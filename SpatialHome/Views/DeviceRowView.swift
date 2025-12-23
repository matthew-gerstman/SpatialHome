import SwiftUI

/// A row displaying a single device with its icon, name, and state
struct DeviceRowView: View {
    let device: HomeDevice
    let isPlaced: Bool
    let onToggle: () async -> Void
    let onPlace: () -> Void
    
    @State private var isToggling = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Device icon with state indicator
            ZStack {
                Circle()
                    .fill(device.isOn ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: device.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(device.isOn ? .yellow : .secondary)
            }
            
            // Device info
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(device.roomName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Placement indicator
            if isPlaced {
                Image(systemName: "cube.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            
            // Toggle button (if device supports it)
            if device.supportsOnOff {
                Button {
                    Task {
                        isToggling = true
                        await onToggle()
                        isToggling = false
                    }
                } label: {
                    if isToggling {
                        ProgressView()
                            .frame(width: 51, height: 31)
                    } else {
                        Toggle("", isOn: .constant(device.isOn))
                            .labelsHidden()
                            .allowsHitTesting(false)
                    }
                }
                .buttonStyle(.plain)
            }
            
            // Place button
            Button {
                onPlace()
            } label: {
                Image(systemName: isPlaced ? "cube.fill" : "cube")
                    .foregroundStyle(isPlaced ? .blue : .secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack(spacing: 12) {
        DeviceRowView(
            device: HomeDevice(name: "Living Room Light", roomName: "Living Room", type: .light, isOn: true),
            isPlaced: true,
            onToggle: {},
            onPlace: {}
        )
        
        DeviceRowView(
            device: HomeDevice(name: "Bedroom Outlet", roomName: "Bedroom", type: .outlet, isOn: false),
            isPlaced: false,
            onToggle: {},
            onPlace: {}
        )
        
        DeviceRowView(
            device: HomeDevice(name: "Motion Sensor", roomName: "Hallway", type: .sensor, isOn: false),
            isPlaced: false,
            onToggle: {},
            onPlace: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
