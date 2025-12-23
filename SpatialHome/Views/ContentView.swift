import SwiftUI

struct ContentView: View {
    @State private var selectedDevice: HomeDevice?
    @State private var isPlacingDevice = false
    
    var body: some View {
        ZStack {
            // Main spatial view (placeholder for RealityKit content)
            SpatialBackgroundView()
            
            // Floating device panel
            VStack {
                Spacer()
                
                HStack {
                    DevicePanelView(
                        homeKitService: MockHomeKitService(),
                        persistenceService: MockAnchorPersistenceService(),
                        onPlaceDevice: { device in
                            selectedDevice = device
                            isPlacingDevice = true
                        }
                    )
                    
                    Spacer()
                }
                .padding()
            }
        }
        .sheet(isPresented: $isPlacingDevice) {
            if let device = selectedDevice {
                PlacementInstructionsView(device: device) {
                    isPlacingDevice = false
                    selectedDevice = nil
                }
            }
        }
    }
}

/// Placeholder background for spatial content
struct SpatialBackgroundView: View {
    var body: some View {
        ZStack {
            Color.clear
            
            VStack(spacing: 20) {
                Image(systemName: "visionpro")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary.opacity(0.5))
                
                Text("Spatial View")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text("Place devices in your space using the panel")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

/// Instructions view shown when placing a device
struct PlacementInstructionsView: View {
    let device: HomeDevice
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: device.iconName)
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            
            Text("Place \(device.name)")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Look at where you want to place this device in your space, then tap to confirm.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "1.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Look at the physical location")
                        .font(.subheadline)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "2.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Tap to place the control")
                        .font(.subheadline)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "3.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Tap the control to toggle")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button("Cancel") {
                onDismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
        .frame(width: 400)
    }
}

#Preview {
    ContentView()
}
