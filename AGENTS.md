# SpatialHome - Agent Handoff Document

## Project Overview

**SpatialHome** is a Vision Pro app that integrates with Apple HomeKit to spatially map smart home devices to their physical locations, enabling users to control devices by tapping on them in AR.

**Repository:** https://github.com/matthew-gerstman/SpatialHome  
**Platform:** visionOS 1.0+  
**Language:** Swift 5.9  
**Owner:** Matthew Gerstman <mattgerstman@gmail.com>

---

## Architecture

```
SpatialHome/
├── App/
│   └── SpatialHomeApp.swift       # @main entry, WindowGroup + ImmersiveSpace scenes
├── Models/
│   ├── HomeDevice.swift           # Device model with DeviceType enum
│   ├── HomeRoom.swift             # Room container with devices array
│   ├── SpatialAnchor.swift        # 3D position/rotation (SIMD3<Float>, simd_quatf)
│   └── DevicePlacement.swift      # Links deviceId to SpatialAnchor
├── Services/
│   ├── HomeKitService.swift       # Protocol + real HMHome implementation
│   ├── MockHomeKitService.swift   # Mock with sample data for testing
│   ├── AnchorPersistenceService.swift    # JSON file storage for placements
│   └── MockAnchorPersistenceService.swift
├── ViewModels/
│   ├── HomeViewModel.swift        # Device list, filtering, toggle actions
│   ├── SpatialPlacementViewModel.swift   # Placement CRUD operations
│   └── DeviceControlViewModel.swift      # Single device control state
├── Views/
│   ├── ContentView.swift          # Main view with panel + placement flow
│   ├── DeviceListView.swift       # Scrollable device list with search/filter
│   ├── DeviceRowView.swift        # Individual device row component
│   ├── DevicePanelView.swift      # Floating ornament-style panel
│   └── ImmersiveSpaceView.swift   # RealityView with gesture handling
├── Spatial/
│   ├── DeviceEntity.swift         # RealityKit Entity subclass
│   └── SpatialDeviceManager.swift # Entity lifecycle management
└── Resources/
    ├── Assets.xcassets
    ├── Info.plist                 # HomeKit usage description
    └── SpatialHome.entitlements   # HomeKit + spatial-personas
```

---

## Key Patterns

### Dependency Injection
All services use protocols for testability:
```swift
protocol HomeKitServiceProtocol {
    func requestAuthorization() async throws
    func fetchRoomsAndDevices() async throws -> [HomeRoom]
    func toggleDevice(_ device: HomeDevice) async throws -> Bool
    // ...
}
```

ViewModels accept services via init:
```swift
init(homeKitService: HomeKitServiceProtocol = HomeKitService())
```

### Mock Services
Debug builds auto-use mocks (see `SpatialHomeApp.swift`):
```swift
#if DEBUG
self.homeKitService = MockHomeKitService()
#else
self.homeKitService = HomeKitService()
#endif
```

`MockHomeKitService` provides 4 rooms with 13 devices for UI testing without hardware.

### Persistence
Placements stored as JSON in app documents directory:
- File: `device_placements.json`
- Format: Array of `DevicePlacement` (Codable)
- Location: `FileManager.default.urls(for: .documentDirectory)`

### RealityKit Integration
- `DeviceEntity`: Visual sphere with state-based color (yellow=on, gray=off)
- `SpatialDeviceManager`: Creates/removes entities, handles tap-to-toggle
- `ImmersiveSpaceView`: RealityView with SpatialTapGesture

---

## Build & Run

### Requirements
- Xcode 15.0+
- visionOS SDK 1.0+
- Vision Pro simulator or device

### Opening the Project
**Option 1 (Recommended):** Open `SpatialHome.xcodeproj`  
**Option 2 (SPM):** File → Open → select `Package.swift`

### Running
1. Select "Apple Vision Pro" simulator
2. Build & Run (⌘R)
3. App launches with mock data in DEBUG mode

### Testing
```bash
xcodebuild test \
  -scheme SpatialHome \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro'
```

---

## Test Coverage

| Layer | File | Tests |
|-------|------|-------|
| Models | HomeDeviceTests.swift | Type mapping, icons, Codable |
| Models | HomeRoomTests.swift | Device filtering, counts |
| Models | DevicePlacementTests.swift | Position updates, transforms |
| Services | HomeKitServiceTests.swift | Mock fetch, toggle, authorization |
| Services | AnchorPersistenceServiceTests.swift | Load, save, delete, update |
| ViewModels | ViewModelTests.swift | All 3 ViewModels |

---

## Common Tasks

### Add a New Device Type
1. Add case to `DeviceType` enum in `HomeDevice.swift`
2. Update `iconName` computed property
3. Update `supportsOnOff` if needed
4. Update `init(from accessory:)` in `HomeKitService.swift`

### Add a New View
1. Create SwiftUI view in `Views/`
2. Add to appropriate scene in `SpatialHomeApp.swift`
3. Update `project.pbxproj` (add PBXFileReference + PBXBuildFile)

### Modify Persistence Schema
1. Update `DevicePlacement` or `SpatialAnchor` structs
2. Consider migration strategy for existing data
3. Update mock service to match

### Debug Placement Issues
1. Check `SpatialDeviceManager.loadSavedPlacements()`
2. Verify JSON file contents in app sandbox
3. Use `MockAnchorPersistenceService.addSamplePlacements()` for testing

---

## Known Limitations

1. **No real HomeKit testing** - Requires physical devices + Home app setup
2. **Placement persistence** - Uses local JSON, not CloudKit
3. **Entity visuals** - Basic spheres, no custom 3D models yet
4. **No room scene understanding** - Placements are absolute, not anchored to surfaces

---

## Future Enhancements

- [ ] CloudKit sync for placements across devices
- [ ] Custom 3D models per device type
- [ ] ARKit scene understanding for surface anchoring
- [ ] Siri Shortcuts integration
- [ ] Widget for quick device access
- [ ] Multi-home support

---

## Troubleshooting

### Xcode Project Won't Open
- Try opening `Package.swift` instead
- Delete `DerivedData` and retry
- Regenerate project with fresh UUIDs if needed

### HomeKit Authorization Fails
- Check `Info.plist` has `NSHomeKitUsageDescription`
- Check `SpatialHome.entitlements` has `com.apple.developer.homekit`
- Ensure simulator/device has Home app configured

### Entities Not Appearing
- Verify `ImmersiveSpace` is opened (check `immersiveSpaceIsShown`)
- Check `SpatialDeviceManager.rootEntity` is set
- Confirm placements loaded via `loadSavedPlacements()`

### Tests Failing
- Ensure using mock services, not real HomeKit
- Check `@MainActor` annotations on async tests
- Verify mock data matches expected test values

---

## Contact

**Owner:** Matthew Gerstman  
**Email:** mattgerstman@gmail.com  
**GitHub:** https://github.com/matthew-gerstman
