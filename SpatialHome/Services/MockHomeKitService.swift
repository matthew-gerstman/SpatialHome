import Foundation

/// Mock implementation of HomeKitService for testing and previews
final class MockHomeKitService: HomeKitServiceProtocol {
    
    // MARK: - Configurable Test Data
    
    var mockRooms: [HomeRoom] = MockHomeKitService.defaultMockRooms
    var shouldFailAuthorization = false
    var shouldFailFetch = false
    var shouldFailToggle = false
    var toggleDelay: TimeInterval = 0.1
    
    // Track calls for testing
    var fetchCallCount = 0
    var toggleCallCount = 0
    var setDevicePowerCallCount = 0
    
    // MARK: - HomeKitServiceProtocol
    
    func requestAuthorization() async throws {
        if shouldFailAuthorization {
            throw HomeKitError.notAuthorized
        }
        // Simulate async delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    func fetchRoomsAndDevices() async throws -> [HomeRoom] {
        fetchCallCount += 1
        
        if shouldFailFetch {
            throw HomeKitError.homeNotFound
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        return mockRooms
    }
    
    func toggleDevice(_ device: HomeDevice) async throws -> Bool {
        toggleCallCount += 1
        
        if shouldFailToggle {
            throw HomeKitError.operationFailed("Mock toggle failure")
        }
        
        // Simulate delay
        try await Task.sleep(nanoseconds: UInt64(toggleDelay * 1_000_000_000))
        
        // Find and toggle the device in our mock data
        let newState = !device.isOn
        updateDeviceState(deviceId: device.id, isOn: newState)
        
        return newState
    }
    
    func setDevicePower(_ device: HomeDevice, isOn: Bool) async throws {
        setDevicePowerCallCount += 1
        
        if shouldFailToggle {
            throw HomeKitError.operationFailed("Mock set power failure")
        }
        
        guard device.supportsOnOff else {
            throw HomeKitError.controlNotSupported
        }
        
        // Simulate delay
        try await Task.sleep(nanoseconds: UInt64(toggleDelay * 1_000_000_000))
        
        updateDeviceState(deviceId: device.id, isOn: isOn)
    }
    
    func getDevicePowerState(_ device: HomeDevice) async throws -> Bool {
        // Find the device in our mock data
        for room in mockRooms {
            if let foundDevice = room.devices.first(where: { $0.id == device.id }) {
                return foundDevice.isOn
            }
        }
        throw HomeKitError.deviceNotFound
    }
    
    // MARK: - Helper Methods
    
    private func updateDeviceState(deviceId: UUID, isOn: Bool) {
        for roomIndex in mockRooms.indices {
            for deviceIndex in mockRooms[roomIndex].devices.indices {
                if mockRooms[roomIndex].devices[deviceIndex].id == deviceId {
                    mockRooms[roomIndex].devices[deviceIndex].isOn = isOn
                    return
                }
            }
        }
    }
    
    /// Reset all tracking and restore default mock data
    func reset() {
        mockRooms = MockHomeKitService.defaultMockRooms
        shouldFailAuthorization = false
        shouldFailFetch = false
        shouldFailToggle = false
        toggleDelay = 0.1
        fetchCallCount = 0
        toggleCallCount = 0
        setDevicePowerCallCount = 0
    }
    
    // MARK: - Default Mock Data
    
    static var defaultMockRooms: [HomeRoom] {
        [
            HomeRoom(
                name: "Living Room",
                devices: [
                    HomeDevice(name: "Ceiling Light", roomName: "Living Room", type: .light, isOn: true),
                    HomeDevice(name: "Floor Lamp", roomName: "Living Room", type: .light, isOn: false),
                    HomeDevice(name: "TV Outlet", roomName: "Living Room", type: .outlet, isOn: true),
                    HomeDevice(name: "Fan", roomName: "Living Room", type: .fan, isOn: false)
                ]
            ),
            HomeRoom(
                name: "Bedroom",
                devices: [
                    HomeDevice(name: "Bedside Lamp", roomName: "Bedroom", type: .light, isOn: false),
                    HomeDevice(name: "Overhead Light", roomName: "Bedroom", type: .light, isOn: false),
                    HomeDevice(name: "Smart Plug", roomName: "Bedroom", type: .outlet, isOn: true)
                ]
            ),
            HomeRoom(
                name: "Kitchen",
                devices: [
                    HomeDevice(name: "Kitchen Lights", roomName: "Kitchen", type: .light, isOn: true),
                    HomeDevice(name: "Under Cabinet", roomName: "Kitchen", type: .light, isOn: false),
                    HomeDevice(name: "Coffee Maker", roomName: "Kitchen", type: .outlet, isOn: false)
                ]
            ),
            HomeRoom(
                name: "Office",
                devices: [
                    HomeDevice(name: "Desk Lamp", roomName: "Office", type: .light, isOn: true),
                    HomeDevice(name: "Monitor Outlet", roomName: "Office", type: .outlet, isOn: true),
                    HomeDevice(name: "Standing Fan", roomName: "Office", type: .fan, isOn: false)
                ]
            )
        ]
    }
}
