import SwiftUI

/// A view displaying all devices grouped by room
struct DeviceListView: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @ObservedObject var placementViewModel: SpatialPlacementViewModel
    
    let onPlaceDevice: (HomeDevice) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with stats
            headerView
            
            // Search bar
            searchBar
            
            // Room filter
            roomFilter
            
            // Device list
            if homeViewModel.isLoading {
                loadingView
            } else if homeViewModel.rooms.isEmpty {
                emptyView
            } else {
                deviceList
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Devices")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(homeViewModel.totalDeviceCount) devices • \(homeViewModel.onDeviceCount) on")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                Task {
                    await homeViewModel.fetchDevices()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .disabled(homeViewModel.isLoading)
        }
        .padding()
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search devices...", text: $homeViewModel.searchText)
                .textFieldStyle(.plain)
            
            if !homeViewModel.searchText.isEmpty {
                Button {
                    homeViewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
    
    private var roomFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All rooms button
                FilterChip(
                    title: "All",
                    isSelected: homeViewModel.selectedRoom == nil,
                    action: { homeViewModel.selectRoom(nil) }
                )
                
                // Individual room buttons
                ForEach(homeViewModel.rooms) { room in
                    FilterChip(
                        title: room.name,
                        isSelected: homeViewModel.selectedRoom?.id == room.id,
                        action: { homeViewModel.selectRoom(room) }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
    
    private var deviceList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(homeViewModel.filteredDevices) { device in
                    DeviceRowView(
                        device: device,
                        isPlaced: placementViewModel.isDevicePlaced(device),
                        onToggle: {
                            _ = await homeViewModel.toggleDevice(device)
                        },
                        onPlace: {
                            onPlaceDevice(device)
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading devices...")
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "house")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No devices found")
                .font(.headline)
            Text("Make sure you have HomeKit devices set up in the Home app.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Refresh") {
                Task {
                    await homeViewModel.fetchDevices()
                }
            }
            .buttonStyle(.bordered)
            
            Spacer()
        }
        .padding()
    }
}

/// A filter chip button for room selection
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let homeVM = HomeViewModel(homeKitService: MockHomeKitService())
    let placementVM = SpatialPlacementViewModel(persistenceService: MockAnchorPersistenceService())
    
    DeviceListView(
        homeViewModel: homeVM,
        placementViewModel: placementVM,
        onPlaceDevice: { _ in }
    )
    .task {
        await homeVM.fetchDevices()
    }
}
