import XCTest
import simd
@testable import SpatialHome

final class DevicePlacementTests: XCTestCase {
    
    // MARK: - SpatialAnchor Tests
    
    func testSpatialAnchorInitialization() {
        let position = SIMD3<Float>(1.0, 2.0, 3.0)
        let rotation = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])
        
        let anchor = SpatialAnchor(position: position, rotation: rotation)
        
        XCTAssertEqual(anchor.position.x, 1.0, accuracy: 0.001)
        XCTAssertEqual(anchor.position.y, 2.0, accuracy: 0.001)
        XCTAssertEqual(anchor.position.z, 3.0, accuracy: 0.001)
    }
    
    func testSpatialAnchorDefaultRotation() {
        let anchor = SpatialAnchor(position: SIMD3<Float>(0, 0, 0))
        
        // Default rotation should be identity-ish (angle 0)
        XCTAssertEqual(anchor.rotation.angle, 0, accuracy: 0.001)
    }
    
    func testSpatialAnchorCodable() throws {
        let position = SIMD3<Float>(1.5, 2.5, 3.5)
        let rotation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
        let anchor = SpatialAnchor(id: UUID(), position: position, rotation: rotation)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(anchor)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SpatialAnchor.self, from: data)
        
        XCTAssertEqual(anchor.id, decoded.id)
        XCTAssertEqual(anchor.position.x, decoded.position.x, accuracy: 0.001)
        XCTAssertEqual(anchor.position.y, decoded.position.y, accuracy: 0.001)
        XCTAssertEqual(anchor.position.z, decoded.position.z, accuracy: 0.001)
    }
    
    func testSpatialAnchorTransform() {
        let position = SIMD3<Float>(1.0, 2.0, 3.0)
        let anchor = SpatialAnchor(position: position)
        
        let transform = anchor.transform
        
        XCTAssertEqual(transform.columns.3.x, 1.0, accuracy: 0.001)
        XCTAssertEqual(transform.columns.3.y, 2.0, accuracy: 0.001)
        XCTAssertEqual(transform.columns.3.z, 3.0, accuracy: 0.001)
        XCTAssertEqual(transform.columns.3.w, 1.0, accuracy: 0.001)
    }
    
    // MARK: - DevicePlacement Tests
    
    func testDevicePlacementInitialization() {
        let deviceId = UUID()
        let anchor = SpatialAnchor(position: SIMD3<Float>(1, 1, 1))
        
        let placement = DevicePlacement(deviceId: deviceId, anchor: anchor)
        
        XCTAssertEqual(placement.deviceId, deviceId)
        XCTAssertEqual(placement.anchor.position.x, 1.0, accuracy: 0.001)
    }
    
    func testDevicePlacementUpdatePosition() {
        let deviceId = UUID()
        let anchor = SpatialAnchor(position: SIMD3<Float>(0, 0, 0))
        var placement = DevicePlacement(deviceId: deviceId, anchor: anchor)
        
        let originalUpdatedAt = placement.updatedAt
        
        // Wait a tiny bit to ensure timestamp changes
        Thread.sleep(forTimeInterval: 0.01)
        
        placement.updatePosition(SIMD3<Float>(5, 5, 5))
        
        XCTAssertEqual(placement.anchor.position.x, 5.0, accuracy: 0.001)
        XCTAssertEqual(placement.anchor.position.y, 5.0, accuracy: 0.001)
        XCTAssertEqual(placement.anchor.position.z, 5.0, accuracy: 0.001)
        XCTAssertGreaterThan(placement.updatedAt, originalUpdatedAt)
    }
    
    func testDevicePlacementUpdateTransform() {
        let deviceId = UUID()
        let anchor = SpatialAnchor(position: SIMD3<Float>(0, 0, 0))
        var placement = DevicePlacement(deviceId: deviceId, anchor: anchor)
        
        let newPosition = SIMD3<Float>(10, 20, 30)
        let newRotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
        
        placement.updateTransform(position: newPosition, rotation: newRotation)
        
        XCTAssertEqual(placement.anchor.position.x, 10.0, accuracy: 0.001)
        XCTAssertEqual(placement.anchor.position.y, 20.0, accuracy: 0.001)
        XCTAssertEqual(placement.anchor.position.z, 30.0, accuracy: 0.001)
    }
    
    func testDevicePlacementCodable() throws {
        let deviceId = UUID()
        let anchor = SpatialAnchor(position: SIMD3<Float>(1, 2, 3))
        let placement = DevicePlacement(id: UUID(), deviceId: deviceId, anchor: anchor)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(placement)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DevicePlacement.self, from: data)
        
        XCTAssertEqual(placement.id, decoded.id)
        XCTAssertEqual(placement.deviceId, decoded.deviceId)
        XCTAssertEqual(placement.anchor.position.x, decoded.anchor.position.x, accuracy: 0.001)
    }
    
    func testDevicePlacementEquality() {
        let id = UUID()
        let deviceId = UUID()
        let anchor = SpatialAnchor(position: SIMD3<Float>(1, 1, 1))
        let date = Date()
        
        let placement1 = DevicePlacement(id: id, deviceId: deviceId, anchor: anchor, createdAt: date, updatedAt: date)
        let placement2 = DevicePlacement(id: id, deviceId: deviceId, anchor: anchor, createdAt: date, updatedAt: date)
        let placement3 = DevicePlacement(id: UUID(), deviceId: deviceId, anchor: anchor)
        
        XCTAssertEqual(placement1, placement2)
        XCTAssertNotEqual(placement1, placement3)
    }
}
