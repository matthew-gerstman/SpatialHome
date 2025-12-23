import SwiftUI
import RealityKit

/// The immersive space view for placing and interacting with devices
struct ImmersiveSpaceView: View {
    @StateObject private var deviceManager: SpatialDeviceManager
    @ObservedObject var homeViewModel: HomeViewModel
    @ObservedObject var placementViewModel: SpatialPlacementViewModel
    
    @State private var placementIndicator: Entity?
    
    init(
        homeViewModel: HomeViewModel,
        placementViewModel: SpatialPlacementViewModel,
        homeKitService: HomeKitServiceProtocol,
        persistenceService: AnchorPersistenceServiceProtocol
    ) {
        self.homeViewModel = homeViewModel
        self.placementViewModel = placementViewModel
        _deviceManager = StateObject(wrappedValue: SpatialDeviceManager(
            homeKitService: homeKitService,
            persistenceService: persistenceService
        ))
    }
    
    var body: some View {
        RealityView { content in
            // Create root entity
            let root = Entity()
            content.add(root)
            
            // Set up device manager
            deviceManager.setRootEntity(root)
            
            // Load existing placements
            deviceManager.loadSavedPlacements(devices: homeViewModel.allDevices)
            
            // Create placement indicator (hidden by default)
            let indicator = createPlacementIndicator()
            indicator.isEnabled = false
            root.addChild(indicator)
            placementIndicator = indicator
            
        } update: { content in
            // Update placement indicator visibility
            placementIndicator?.isEnabled = deviceManager.isPlacingDevice
        }
        .gesture(tapGesture)
        .gesture(dragGesture)
    }
    
    // MARK: - Gestures
    
    private var tapGesture: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                handleTap(at: value.location3D, on: value.entity)
            }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                handleDrag(value)
            }
            .onEnded { value in
                handleDragEnd(value)
            }
    }
    
    // MARK: - Gesture Handlers
    
    private func handleTap(at location: SIMD3<Float>, on entity: Entity) {
        if deviceManager.isPlacingDevice {
            // Place the device at the tapped location
            if let placement = deviceManager.placeDevice(at: location) {
                // Update placement view model
                if let device = deviceManager.deviceToPlace {
                    _ = placementViewModel.placeDevice(device, at: location)
                }
            }
        } else if let deviceEntity = entity as? DeviceEntity {
            // Toggle the device
            Task {
                await deviceEntity.handleTap()
                
                // Sync state back to view model
                if let newState = await homeViewModel.toggleDevice(deviceEntity.device) {
                    deviceEntity.isOn = newState
                }
            }
        }
    }
    
    private func handleDrag(_ value: DragGesture.Value) {
        // Could be used for repositioning devices
    }
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        // Finalize repositioning
    }
    
    // MARK: - Helpers
    
    private func createPlacementIndicator() -> Entity {
        let mesh = MeshResource.generateSphere(radius: 0.03)
        var material = SimpleMaterial()
        material.color = .init(tint: .systemBlue.withAlphaComponent(0.5))
        
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "PlacementIndicator"
        
        return entity
    }
    
    // MARK: - Public Methods
    
    func startPlacingDevice(_ device: HomeDevice) {
        deviceManager.startPlacing(device)
    }
    
    func cancelPlacement() {
        deviceManager.cancelPlacing()
    }
}

// MARK: - Preview

#Preview {
    let homeVM = HomeViewModel(homeKitService: MockHomeKitService())
    let placementVM = SpatialPlacementViewModel(persistenceService: MockAnchorPersistenceService())
    
    ImmersiveSpaceView(
        homeViewModel: homeVM,
        placementViewModel: placementVM,
        homeKitService: MockHomeKitService(),
        persistenceService: MockAnchorPersistenceService()
    )
}
