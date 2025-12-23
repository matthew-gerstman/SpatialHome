import RealityKit
import ARKit
import Combine

/// Manages spatial device entities in the RealityKit scene
@MainActor
class SpatialDeviceManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var deviceEntities: [UUID: DeviceEntity] = [:]
    @Published private(set) var isPlacingDevice = false
    @Published var deviceToPlace: HomeDevice?
    
    // MARK: - Dependencies
    
    private let homeKitService: HomeKitServiceProtocol
    private let persistenceService: AnchorPersistenceServiceProtocol
    
    // MARK: - RealityKit
    
    weak var rootEntity: Entity?
    
    // MARK: - Initialization
    
    init(
        homeKitService: HomeKitServiceProtocol,
        persistenceService: AnchorPersistenceServiceProtocol
    ) {
        self.homeKitService = homeKitService
        self.persistenceService = persistenceService
    }
    
    // MARK: - Setup
    
    /// Set the root entity for adding device entities
    func setRootEntity(_ entity: Entity) {
        self.rootEntity = entity
    }
    
    /// Load all saved placements and create entities
    func loadSavedPlacements(devices: [HomeDevice]) {
        do {
            let placements = try persistenceService.loadPlacements()
            
            for placement in placements {
                if let device = devices.first(where: { $0.id == placement.deviceId }) {
                    createDeviceEntity(for: device, at: placement)
                }
            }
        } catch {
            print("Failed to load placements: \(error)")
        }
    }
    
    // MARK: - Device Placement
    
    /// Start placing a device
    func startPlacing(_ device: HomeDevice) {
        deviceToPlace = device
        isPlacingDevice = true
    }
    
    /// Cancel device placement
    func cancelPlacing() {
        deviceToPlace = nil
        isPlacingDevice = false
    }
    
    /// Place the current device at a position
    func placeDevice(at position: SIMD3<Float>) -> DevicePlacement? {
        guard let device = deviceToPlace else { return nil }
        
        let anchor = SpatialAnchor(position: position)
        let placement = DevicePlacement(deviceId: device.id, anchor: anchor)
        
        do {
            try persistenceService.savePlacement(placement)
            createDeviceEntity(for: device, at: placement)
            
            deviceToPlace = nil
            isPlacingDevice = false
            
            return placement
        } catch {
            print("Failed to save placement: \(error)")
            return nil
        }
    }
    
    // MARK: - Entity Management
    
    /// Create a device entity and add it to the scene
    private func createDeviceEntity(for device: HomeDevice, at placement: DevicePlacement) {
        let entity = DeviceEntity(device: device, placement: placement) { [weak self] tappedEntity in
            await self?.handleDeviceTap(tappedEntity)
        }
        
        rootEntity?.addChild(entity)
        deviceEntities[device.id] = entity
    }
    
    /// Remove a device entity from the scene
    func removeDeviceEntity(for deviceId: UUID) {
        guard let entity = deviceEntities[deviceId] else { return }
        
        entity.removeFromParent()
        deviceEntities.removeValue(forKey: deviceId)
        
        do {
            try persistenceService.deletePlacement(forDeviceId: deviceId)
        } catch {
            print("Failed to delete placement: \(error)")
        }
    }
    
    /// Update a device entity's position
    func updateDevicePosition(_ deviceId: UUID, to position: SIMD3<Float>) {
        guard let entity = deviceEntities[deviceId] else { return }
        
        entity.updatePosition(position)
        
        do {
            try persistenceService.updatePlacement(entity.placement)
        } catch {
            print("Failed to update placement: \(error)")
        }
    }
    
    /// Update device state (on/off)
    func updateDeviceState(_ deviceId: UUID, isOn: Bool) {
        deviceEntities[deviceId]?.isOn = isOn
    }
    
    // MARK: - Interaction
    
    /// Handle a tap on a device entity
    private func handleDeviceTap(_ entity: DeviceEntity) async {
        guard entity.device.supportsOnOff else { return }
        
        do {
            let newState = try await homeKitService.toggleDevice(entity.device)
            entity.isOn = newState
        } catch {
            print("Failed to toggle device: \(error)")
        }
    }
    
    /// Find the device entity at a given position (for ray casting)
    func findDeviceEntity(at position: SIMD3<Float>, radius: Float = 0.1) -> DeviceEntity? {
        for entity in deviceEntities.values {
            let distance = simd_distance(entity.position, position)
            if distance < radius {
                return entity
            }
        }
        return nil
    }
    
    // MARK: - Cleanup
    
    /// Remove all device entities
    func clearAllEntities() {
        for entity in deviceEntities.values {
            entity.removeFromParent()
        }
        deviceEntities.removeAll()
    }
}
