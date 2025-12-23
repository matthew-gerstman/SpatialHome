import XCTest
import simd
@testable import SpatialHome

final class AnchorPersistenceServiceTests: XCTestCase {
    
    var mockService: MockAnchorPersistenceService!
    
    override func setUp() {
        super.setUp()
        mockService = MockAnchorPersistenceService()
    }
    
    override func tearDown() {
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - Load Tests
    
    func testLoadEmptyPlacements() throws {
        let placements = try mockService.loadPlacements()
        
        XCTAssertTrue(placements.isEmpty)
        XCTAssertEqual(mockService.loadCallCount, 1)
    }
    
    func testLoadPlacementsFailure() {
        mockService.shouldFailLoad = true
        
        XCTAssertThrowsError(try mockService.loadPlacements()) { error in
            XCTAssertTrue(error is PersistenceError)
        }
    }
    
    // MARK: - Save Tests
    
    func testSavePlacement() throws {
        let deviceId = UUID()
        let anchor = SpatialAnchor(position: SIMD3<Float>(1, 2, 3))
        let placement = DevicePlacement(deviceId: deviceId, anchor: anchor)
        
        try mockService.savePlacement(placement)
        
        let loaded = try mockService.loadPlacements()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.deviceId, deviceId)
        XCTAssertEqual(mockService.saveCallCount, 1)
    }
    
    func testSavePlacementReplacesExisting() throws {
        let deviceId = UUID()
        
        // Save first placement
        let anchor1 = SpatialAnchor(position: SIMD3<Float>(1, 1, 1))
        let placement1 = DevicePlacement(deviceId: deviceId, anchor: anchor1)
        try mockService.savePlacement(placement1)
        
        // Save second placement for same device
        let anchor2 = SpatialAnchor(position: SIMD3<Float>(2, 2, 2))
        let placement2 = DevicePlacement(deviceId: deviceId, anchor: anchor2)
        try mockService.savePlacement(placement2)
        
        // Should only have one placement
        let loaded = try mockService.loadPlacements()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.anchor.position.x, 2.0, accuracy: 0.001)
    }
    
    func testSavePlacementFailure() {
        mockService.shouldFailSave = true
        
        let placement = DevicePlacement(
            deviceId: UUID(),
            anchor: SpatialAnchor(position: SIMD3<Float>(0, 0, 0))
        )
        
        XCTAssertThrowsError(try mockService.savePlacement(placement)) { error in
            XCTAssertTrue(error is PersistenceError)
        }
    }
    
    // MARK: - Delete Tests
    
    func testDeletePlacementById() throws {
        let deviceId = UUID()
        let anchor = SpatialAnchor(position: SIMD3<Float>(0, 0, 0))
        let placement = DevicePlacement(deviceId: deviceId, anchor: anchor)
        
        try mockService.savePlacement(placement)
        XCTAssertEqual(try mockService.loadPlacements().count, 1)
        
        try mockService.deletePlacement(id: placement.id)
        XCTAssertEqual(try mockService.loadPlacements().count, 0)
        XCTAssertEqual(mockService.deleteCallCount, 1)
    }
    
    func testDeletePlacementByDeviceId() throws {
        let deviceId = UUID()
        let anchor = SpatialAnchor(position: SIMD3<Float>(0, 0, 0))
        let placement = DevicePlacement(deviceId: deviceId, anchor: anchor)
        
        try mockService.savePlacement(placement)
        
        try mockService.deletePlacement(forDeviceId: deviceId)
        XCTAssertEqual(try mockService.loadPlacements().count, 0)
    }
    
    func testDeleteNonExistentPlacement() {
        XCTAssertThrowsError(try mockService.deletePlacement(id: UUID())) { error in
            if case PersistenceError.placementNotFound = error {
                // Expected
            } else {
                XCTFail("Expected placementNotFound error")
            }
        }
    }
    
    func testDeleteAllPlacements() throws {
        mockService.addSamplePlacements()
        XCTAssertGreaterThan(try mockService.loadPlacements().count, 0)
        
        try mockService.deleteAllPlacements()
        XCTAssertEqual(try mockService.loadPlacements().count, 0)
    }
    
    // MARK: - Update Tests
    
    func testUpdatePlacement() throws {
        let deviceId = UUID()
        let anchor = SpatialAnchor(position: SIMD3<Float>(1, 1, 1))
        var placement = DevicePlacement(deviceId: deviceId, anchor: anchor)
        
        try mockService.savePlacement(placement)
        
        // Update position
        placement.updatePosition(SIMD3<Float>(5, 5, 5))
        try mockService.updatePlacement(placement)
        
        let loaded = try mockService.loadPlacements().first
        XCTAssertEqual(loaded?.anchor.position.x, 5.0, accuracy: 0.001)
        XCTAssertEqual(mockService.updateCallCount, 1)
    }
    
    func testUpdateNonExistentPlacement() {
        let placement = DevicePlacement(
            deviceId: UUID(),
            anchor: SpatialAnchor(position: SIMD3<Float>(0, 0, 0))
        )
        
        XCTAssertThrowsError(try mockService.updatePlacement(placement)) { error in
            if case PersistenceError.placementNotFound = error {
                // Expected
            } else {
                XCTFail("Expected placementNotFound error")
            }
        }
    }
    
    // MARK: - Query Tests
    
    func testHasPlacement() throws {
        let deviceId = UUID()
        
        XCTAssertFalse(try mockService.hasPlacement(forDeviceId: deviceId))
        
        let placement = DevicePlacement(
            deviceId: deviceId,
            anchor: SpatialAnchor(position: SIMD3<Float>(0, 0, 0))
        )
        try mockService.savePlacement(placement)
        
        XCTAssertTrue(try mockService.hasPlacement(forDeviceId: deviceId))
    }
    
    func testGetPlacement() throws {
        let deviceId = UUID()
        let position = SIMD3<Float>(1, 2, 3)
        let placement = DevicePlacement(
            deviceId: deviceId,
            anchor: SpatialAnchor(position: position)
        )
        
        try mockService.savePlacement(placement)
        
        let retrieved = try mockService.getPlacement(forDeviceId: deviceId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.deviceId, deviceId)
        XCTAssertEqual(retrieved?.anchor.position.x, 1.0, accuracy: 0.001)
    }
    
    func testGetPlacementNotFound() throws {
        let retrieved = try mockService.getPlacement(forDeviceId: UUID())
        XCTAssertNil(retrieved)
    }
    
    // MARK: - Reset Tests
    
    func testReset() throws {
        mockService.addSamplePlacements()
        mockService.shouldFailLoad = true
        _ = try? mockService.loadPlacements()
        
        mockService.reset()
        
        XCTAssertEqual(mockService.placements.count, 0)
        XCTAssertFalse(mockService.shouldFailLoad)
        XCTAssertEqual(mockService.loadCallCount, 0)
    }
    
    // MARK: - Sample Data Tests
    
    func testAddSamplePlacements() throws {
        mockService.addSamplePlacements()
        
        let placements = try mockService.loadPlacements()
        XCTAssertEqual(placements.count, 3)
        
        // Verify positions are spaced correctly
        let positions = placements.map { $0.anchor.position.x }
        XCTAssertTrue(positions.contains { abs($0 - 0.0) < 0.001 })
        XCTAssertTrue(positions.contains { abs($0 - 0.5) < 0.001 })
        XCTAssertTrue(positions.contains { abs($0 - 1.0) < 0.001 })
    }
}
