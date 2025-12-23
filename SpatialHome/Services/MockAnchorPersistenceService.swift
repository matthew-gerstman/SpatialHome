import Foundation

/// Mock implementation of AnchorPersistenceService for testing
final class MockAnchorPersistenceService: AnchorPersistenceServiceProtocol {
    
    // MARK: - In-Memory Storage
    
    var placements: [DevicePlacement] = []
    
    // MARK: - Failure Injection
    
    var shouldFailLoad = false
    var shouldFailSave = false
    var shouldFailDelete = false
    
    // MARK: - Call Tracking
    
    var loadCallCount = 0
    var saveCallCount = 0
    var deleteCallCount = 0
    var updateCallCount = 0
    
    // MARK: - AnchorPersistenceServiceProtocol
    
    func loadPlacements() throws -> [DevicePlacement] {
        loadCallCount += 1
        
        if shouldFailLoad {
            throw PersistenceError.decodingFailed(NSError(domain: "Mock", code: 1))
        }
        
        return placements
    }
    
    func savePlacement(_ placement: DevicePlacement) throws {
        saveCallCount += 1
        
        if shouldFailSave {
            throw PersistenceError.writeFailed(NSError(domain: "Mock", code: 2))
        }
        
        // Remove existing placement for this device
        placements.removeAll { $0.deviceId == placement.deviceId }
        placements.append(placement)
    }
    
    func deletePlacement(id: UUID) throws {
        deleteCallCount += 1
        
        if shouldFailDelete {
            throw PersistenceError.writeFailed(NSError(domain: "Mock", code: 3))
        }
        
        let originalCount = placements.count
        placements.removeAll { $0.id == id }
        
        if placements.count == originalCount {
            throw PersistenceError.placementNotFound
        }
    }
    
    func deletePlacement(forDeviceId deviceId: UUID) throws {
        deleteCallCount += 1
        
        if shouldFailDelete {
            throw PersistenceError.writeFailed(NSError(domain: "Mock", code: 3))
        }
        
        let originalCount = placements.count
        placements.removeAll { $0.deviceId == deviceId }
        
        if placements.count == originalCount {
            throw PersistenceError.placementNotFound
        }
    }
    
    func updatePlacement(_ placement: DevicePlacement) throws {
        updateCallCount += 1
        
        if shouldFailSave {
            throw PersistenceError.writeFailed(NSError(domain: "Mock", code: 4))
        }
        
        guard let index = placements.firstIndex(where: { $0.id == placement.id }) else {
            throw PersistenceError.placementNotFound
        }
        
        placements[index] = placement
    }
    
    func hasPlacement(forDeviceId deviceId: UUID) throws -> Bool {
        if shouldFailLoad {
            throw PersistenceError.decodingFailed(NSError(domain: "Mock", code: 1))
        }
        return placements.contains { $0.deviceId == deviceId }
    }
    
    func getPlacement(forDeviceId deviceId: UUID) throws -> DevicePlacement? {
        if shouldFailLoad {
            throw PersistenceError.decodingFailed(NSError(domain: "Mock", code: 1))
        }
        return placements.first { $0.deviceId == deviceId }
    }
    
    func deleteAllPlacements() throws {
        deleteCallCount += 1
        
        if shouldFailDelete {
            throw PersistenceError.writeFailed(NSError(domain: "Mock", code: 5))
        }
        
        placements.removeAll()
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        placements.removeAll()
        shouldFailLoad = false
        shouldFailSave = false
        shouldFailDelete = false
        loadCallCount = 0
        saveCallCount = 0
        deleteCallCount = 0
        updateCallCount = 0
    }
    
    /// Add sample placements for testing
    func addSamplePlacements() {
        let devices = MockHomeKitService.defaultMockRooms.flatMap { $0.devices }
        
        for (index, device) in devices.prefix(3).enumerated() {
            let position = SIMD3<Float>(Float(index) * 0.5, 1.5, -1.0)
            let anchor = SpatialAnchor(position: position)
            let placement = DevicePlacement(deviceId: device.id, anchor: anchor)
            placements.append(placement)
        }
    }
}
