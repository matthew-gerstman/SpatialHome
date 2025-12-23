import Foundation
import Combine

/// View model for managing device placements in 3D space
@MainActor
final class SpatialPlacementViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var placements: [DevicePlacement] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: PersistenceError?
    
    // MARK: - Computed Properties
    
    /// IDs of devices that have been placed
    var placedDeviceIds: Set<UUID> {
        Set(placements.map { $0.deviceId })
    }
    
    /// Number of placed devices
    var placementCount: Int {
        placements.count
    }
    
    // MARK: - Dependencies
    
    private let persistenceService: AnchorPersistenceServiceProtocol
    
    // MARK: - Initialization
    
    init(persistenceService: AnchorPersistenceServiceProtocol = AnchorPersistenceService()) {
        self.persistenceService = persistenceService
    }
    
    // MARK: - Public Methods
    
    /// Load all saved placements
    func loadPlacements() {
        isLoading = true
        error = nil
        
        do {
            placements = try persistenceService.loadPlacements()
        } catch let error as PersistenceError {
            self.error = error
        } catch {
            self.error = .decodingFailed(error)
        }
        
        isLoading = false
    }
    
    /// Place a device at a spatial position
    func placeDevice(_ device: HomeDevice, at position: SIMD3<Float>, rotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])) -> DevicePlacement? {
        let anchor = SpatialAnchor(position: position, rotation: rotation)
        let placement = DevicePlacement(deviceId: device.id, anchor: anchor)
        
        do {
            try persistenceService.savePlacement(placement)
            
            // Update local state
            placements.removeAll { $0.deviceId == device.id }
            placements.append(placement)
            
            return placement
        } catch let error as PersistenceError {
            self.error = error
            return nil
        } catch {
            self.error = .writeFailed(error)
            return nil
        }
    }
    
    /// Update a placement's position
    func updatePlacementPosition(_ placement: DevicePlacement, to position: SIMD3<Float>) -> Bool {
        var updatedPlacement = placement
        updatedPlacement.updatePosition(position)
        
        do {
            try persistenceService.updatePlacement(updatedPlacement)
            
            // Update local state
            if let index = placements.firstIndex(where: { $0.id == placement.id }) {
                placements[index] = updatedPlacement
            }
            
            return true
        } catch let error as PersistenceError {
            self.error = error
            return false
        } catch {
            self.error = .writeFailed(error)
            return false
        }
    }
    
    /// Update a placement's transform (position and rotation)
    func updatePlacementTransform(_ placement: DevicePlacement, position: SIMD3<Float>, rotation: simd_quatf) -> Bool {
        var updatedPlacement = placement
        updatedPlacement.updateTransform(position: position, rotation: rotation)
        
        do {
            try persistenceService.updatePlacement(updatedPlacement)
            
            // Update local state
            if let index = placements.firstIndex(where: { $0.id == placement.id }) {
                placements[index] = updatedPlacement
            }
            
            return true
        } catch let error as PersistenceError {
            self.error = error
            return false
        } catch {
            self.error = .writeFailed(error)
            return false
        }
    }
    
    /// Remove a device placement
    func removePlacement(forDeviceId deviceId: UUID) -> Bool {
        do {
            try persistenceService.deletePlacement(forDeviceId: deviceId)
            
            // Update local state
            placements.removeAll { $0.deviceId == deviceId }
            
            return true
        } catch let error as PersistenceError {
            self.error = error
            return false
        } catch {
            self.error = .writeFailed(error)
            return false
        }
    }
    
    /// Remove a placement by ID
    func removePlacement(id: UUID) -> Bool {
        do {
            try persistenceService.deletePlacement(id: id)
            
            // Update local state
            placements.removeAll { $0.id == id }
            
            return true
        } catch let error as PersistenceError {
            self.error = error
            return false
        } catch {
            self.error = .writeFailed(error)
            return false
        }
    }
    
    /// Check if a device has been placed
    func isDevicePlaced(_ device: HomeDevice) -> Bool {
        placedDeviceIds.contains(device.id)
    }
    
    /// Get placement for a specific device
    func placement(forDeviceId deviceId: UUID) -> DevicePlacement? {
        placements.first { $0.deviceId == deviceId }
    }
    
    /// Clear all placements
    func clearAllPlacements() -> Bool {
        do {
            try persistenceService.deleteAllPlacements()
            placements.removeAll()
            return true
        } catch let error as PersistenceError {
            self.error = error
            return false
        } catch {
            self.error = .writeFailed(error)
            return false
        }
    }
    
    /// Clear the current error
    func clearError() {
        error = nil
    }
}
