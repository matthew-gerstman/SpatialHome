# SpatialHome

A Vision Pro app that integrates with Apple HomeKit to spatially map smart home devices to their physical locations in a room, enabling users to control devices by tapping directly on them in AR.

## Features

- **HomeKit Integration**: Read and control HomeKit devices (lights, outlets, switches, fans)
- **Spatial Mapping**: Place virtual controls at the physical locations of your devices
- **AR Interaction**: Tap on placed devices to toggle them on/off
- **Persistence**: Device placements are saved and restored between sessions
- **Room Filtering**: Filter devices by room or search by name

## Architecture

The app follows a clean MVVM architecture with protocol-based dependency injection:

```
SpatialHome/
├── App/
│   └── SpatialHomeApp.swift      # App entry point with scenes
├── Models/
│   ├── HomeDevice.swift          # Device model with HomeKit mapping
│   ├── HomeRoom.swift            # Room model with device collection
│   ├── SpatialAnchor.swift       # 3D position/rotation data
│   └── DevicePlacement.swift     # Device-to-anchor mapping
├── Services/
│   ├── HomeKitService.swift      # HomeKit integration
│   ├── MockHomeKitService.swift  # Mock for testing
│   ├── AnchorPersistenceService.swift    # JSON file storage
│   └── MockAnchorPersistenceService.swift
├── ViewModels/
│   ├── HomeViewModel.swift       # Device list management
│   ├── SpatialPlacementViewModel.swift   # Placement management
│   └── DeviceControlViewModel.swift      # Single device control
├── Views/
│   ├── ContentView.swift         # Main content view
│   ├── DeviceListView.swift      # Device list with filtering
│   ├── DeviceRowView.swift       # Individual device row
│   ├── DevicePanelView.swift     # Floating panel for visionOS
│   └── ImmersiveSpaceView.swift  # RealityKit immersive view
└── Spatial/
    ├── DeviceEntity.swift        # RealityKit entity for devices
    └── SpatialDeviceManager.swift # Entity lifecycle management
```

## Requirements

- visionOS 1.0+
- Xcode 15.0+
- HomeKit-enabled smart home devices

## Setup

1. Clone the repository
2. Open `SpatialHome.xcodeproj` in Xcode
3. Set your development team in project settings
4. Build and run on Vision Pro simulator or device

## Usage

1. **Grant HomeKit Access**: The app will request HomeKit permission on first launch
2. **View Devices**: All your HomeKit devices appear in the device panel
3. **Enter Spatial Mode**: Tap "Enter" to open the immersive space
4. **Place Devices**: Select a device and tap in your space to place it
5. **Control Devices**: Tap on placed devices to toggle them on/off

## Testing

The app includes comprehensive unit tests for all layers:

```bash
# Run all tests
xcodebuild test -scheme SpatialHome -destination 'platform=visionOS Simulator,name=Apple Vision Pro'
```

Test coverage includes:
- Model serialization and equality
- Service layer with mock implementations
- ViewModel state management
- Integration scenarios

## Development

### Mock Services

For development without HomeKit hardware, the app uses mock services in DEBUG builds:

```swift
#if DEBUG
self.homeKitService = MockHomeKitService()
self.persistenceService = MockAnchorPersistenceService()
#else
self.homeKitService = HomeKitService()
self.persistenceService = AnchorPersistenceService()
#endif
```

### Adding New Device Types

1. Add the type to `DeviceType` enum in `HomeDevice.swift`
2. Update `iconName` and `supportsOnOff` computed properties
3. Update `init(from accessory:)` mapping in HomeKit service

## License

MIT License - See LICENSE file for details

## Author

Matthew Gerstman
