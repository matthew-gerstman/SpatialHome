import SwiftUI

@main
struct SpatialHomeApp: App {
    
    // MARK: - Services (shared instances)
    
    private let homeKitService: HomeKitServiceProtocol
    private let persistenceService: AnchorPersistenceServiceProtocol
    
    // MARK: - State
    
    @State private var immersiveSpaceIsShown = false
    @State private var showImmersiveSpaceError = false
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    // MARK: - Initialization
    
    init() {
        // Use mock services for development/testing
        // Replace with real services for production:
        // self.homeKitService = HomeKitService()
        // self.persistenceService = AnchorPersistenceService()
        
        #if DEBUG
        self.homeKitService = MockHomeKitService()
        self.persistenceService = MockAnchorPersistenceService()
        #else
        self.homeKitService = HomeKitService()
        self.persistenceService = AnchorPersistenceService()
        #endif
    }
    
    // MARK: - Body
    
    var body: some Scene {
        // Main window with device panel
        WindowGroup {
            MainView(
                homeKitService: homeKitService,
                persistenceService: persistenceService,
                onOpenImmersiveSpace: {
                    Task {
                        let result = await openImmersiveSpace(id: "SpatialHomeSpace")
                        switch result {
                        case .opened:
                            immersiveSpaceIsShown = true
                        case .error:
                            showImmersiveSpaceError = true
                        case .userCancelled:
                            break
                        @unknown default:
                            break
                        }
                    }
                },
                onDismissImmersiveSpace: {
                    Task {
                        await dismissImmersiveSpace()
                        immersiveSpaceIsShown = false
                    }
                },
                immersiveSpaceIsShown: immersiveSpaceIsShown
            )
            .alert("Immersive Space Error", isPresented: $showImmersiveSpaceError) {
                Button("OK") {}
            } message: {
                Text("Unable to open the immersive space. Please try again.")
            }
        }
        .windowStyle(.plain)
        .defaultSize(width: 400, height: 600)
        
        // Immersive space for spatial device placement
        ImmersiveSpace(id: "SpatialHomeSpace") {
            ImmersiveContentView(
                homeKitService: homeKitService,
                persistenceService: persistenceService
            )
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}

// MARK: - Main View

struct MainView: View {
    let homeKitService: HomeKitServiceProtocol
    let persistenceService: AnchorPersistenceServiceProtocol
    let onOpenImmersiveSpace: () -> Void
    let onDismissImmersiveSpace: () -> Void
    let immersiveSpaceIsShown: Bool
    
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var placementViewModel: SpatialPlacementViewModel
    
    init(
        homeKitService: HomeKitServiceProtocol,
        persistenceService: AnchorPersistenceServiceProtocol,
        onOpenImmersiveSpace: @escaping () -> Void,
        onDismissImmersiveSpace: @escaping () -> Void,
        immersiveSpaceIsShown: Bool
    ) {
        self.homeKitService = homeKitService
        self.persistenceService = persistenceService
        self.onOpenImmersiveSpace = onOpenImmersiveSpace
        self.onDismissImmersiveSpace = onDismissImmersiveSpace
        self.immersiveSpaceIsShown = immersiveSpaceIsShown
        
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(homeKitService: homeKitService))
        _placementViewModel = StateObject(wrappedValue: SpatialPlacementViewModel(persistenceService: persistenceService))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Device list
                DeviceListView(
                    homeViewModel: homeViewModel,
                    placementViewModel: placementViewModel,
                    onPlaceDevice: { device in
                        if !immersiveSpaceIsShown {
                            onOpenImmersiveSpace()
                        }
                    }
                )
                
                // Immersive space toggle
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spatial Mode")
                            .font(.headline)
                        Text(immersiveSpaceIsShown ? "Place devices in your space" : "Enter to place devices")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        if immersiveSpaceIsShown {
                            onDismissImmersiveSpace()
                        } else {
                            onOpenImmersiveSpace()
                        }
                    } label: {
                        Label(
                            immersiveSpaceIsShown ? "Exit" : "Enter",
                            systemImage: immersiveSpaceIsShown ? "xmark.circle" : "cube.transparent"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("SpatialHome")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await homeViewModel.fetchDevices()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await homeViewModel.requestAuthorization()
            await homeViewModel.fetchDevices()
            placementViewModel.loadPlacements()
        }
    }
}

// MARK: - Immersive Content View

struct ImmersiveContentView: View {
    let homeKitService: HomeKitServiceProtocol
    let persistenceService: AnchorPersistenceServiceProtocol
    
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var placementViewModel: SpatialPlacementViewModel
    
    init(
        homeKitService: HomeKitServiceProtocol,
        persistenceService: AnchorPersistenceServiceProtocol
    ) {
        self.homeKitService = homeKitService
        self.persistenceService = persistenceService
        
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(homeKitService: homeKitService))
        _placementViewModel = StateObject(wrappedValue: SpatialPlacementViewModel(persistenceService: persistenceService))
    }
    
    var body: some View {
        ImmersiveSpaceView(
            homeViewModel: homeViewModel,
            placementViewModel: placementViewModel,
            homeKitService: homeKitService,
            persistenceService: persistenceService
        )
        .task {
            await homeViewModel.fetchDevices()
            placementViewModel.loadPlacements()
        }
    }
}
