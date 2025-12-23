import SwiftUI

/// A floating panel for device management in visionOS
struct DevicePanelView: View {
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var placementViewModel: SpatialPlacementViewModel
    
    let homeKitService: HomeKitServiceProtocol
    let persistenceService: AnchorPersistenceServiceProtocol
    
    @State private var selectedDeviceForPlacement: HomeDevice?
    @State private var showingError = false
    
    var onPlaceDevice: ((HomeDevice) -> Void)?
    
    init(
        homeKitService: HomeKitServiceProtocol = HomeKitService(),
        persistenceService: AnchorPersistenceServiceProtocol = AnchorPersistenceService(),
        onPlaceDevice: ((HomeDevice) -> Void)? = nil
    ) {
        self.homeKitService = homeKitService
        self.persistenceService = persistenceService
        self.onPlaceDevice = onPlaceDevice
        
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(homeKitService: homeKitService))
        _placementViewModel = StateObject(wrappedValue: SpatialPlacementViewModel(persistenceService: persistenceService))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            DeviceListView(
                homeViewModel: homeViewModel,
                placementViewModel: placementViewModel,
                onPlaceDevice: { device in
                    selectedDeviceForPlacement = device
                    onPlaceDevice?(device)
                }
            )
        }
        .frame(width: 380, height: 500)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .task {
            await homeViewModel.requestAuthorization()
            await homeViewModel.fetchDevices()
            placementViewModel.loadPlacements()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                homeViewModel.clearError()
            }
        } message: {
            if let error = homeViewModel.error {
                Text(error.localizedDescription)
            }
        }
        .onChange(of: homeViewModel.error) { _, newError in
            showingError = newError != nil
        }
    }
    
    // MARK: - Public Methods
    
    /// Refresh devices from HomeKit
    func refresh() async {
        await homeViewModel.fetchDevices()
    }
    
    /// Get the home view model for external access
    var viewModel: HomeViewModel {
        homeViewModel
    }
    
    /// Get the placement view model for external access
    var placementModel: SpatialPlacementViewModel {
        placementViewModel
    }
}

#Preview {
    DevicePanelView(
        homeKitService: MockHomeKitService(),
        persistenceService: MockAnchorPersistenceService()
    )
}
