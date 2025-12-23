import Foundation
import Combine

/// View model for managing HomeKit devices and rooms
@MainActor
final class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var rooms: [HomeRoom] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: HomeKitError?
    @Published var selectedRoom: HomeRoom?
    @Published var searchText = ""
    
    // MARK: - Computed Properties
    
    /// All devices across all rooms
    var allDevices: [HomeDevice] {
        rooms.flatMap { $0.devices }
    }
    
    /// Devices filtered by search text
    var filteredDevices: [HomeDevice] {
        let devices = selectedRoom?.devices ?? allDevices
        
        guard !searchText.isEmpty else {
            return devices
        }
        
        return devices.filter { device in
            device.name.localizedCaseInsensitiveContains(searchText) ||
            device.roomName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    /// Devices that support on/off control
    var controllableDevices: [HomeDevice] {
        filteredDevices.filter { $0.supportsOnOff }
    }
    
    /// Total count of all devices
    var totalDeviceCount: Int {
        allDevices.count
    }
    
    /// Count of devices currently on
    var onDeviceCount: Int {
        allDevices.filter { $0.isOn }.count
    }
    
    // MARK: - Dependencies
    
    private let homeKitService: HomeKitServiceProtocol
    
    // MARK: - Initialization
    
    init(homeKitService: HomeKitServiceProtocol = HomeKitService()) {
        self.homeKitService = homeKitService
    }
    
    // MARK: - Public Methods
    
    /// Request HomeKit authorization
    func requestAuthorization() async {
        do {
            try await homeKitService.requestAuthorization()
        } catch let error as HomeKitError {
            self.error = error
        } catch {
            self.error = .operationFailed(error.localizedDescription)
        }
    }
    
    /// Fetch all rooms and devices from HomeKit
    func fetchDevices() async {
        isLoading = true
        error = nil
        
        do {
            rooms = try await homeKitService.fetchRoomsAndDevices()
        } catch let error as HomeKitError {
            self.error = error
        } catch {
            self.error = .operationFailed(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    /// Toggle a device's power state
    func toggleDevice(_ device: HomeDevice) async -> Bool? {
        do {
            let newState = try await homeKitService.toggleDevice(device)
            
            // Update local state
            updateDeviceState(deviceId: device.id, isOn: newState)
            
            return newState
        } catch let error as HomeKitError {
            self.error = error
            return nil
        } catch {
            self.error = .operationFailed(error.localizedDescription)
            return nil
        }
    }
    
    /// Set a device's power state explicitly
    func setDevicePower(_ device: HomeDevice, isOn: Bool) async -> Bool {
        do {
            try await homeKitService.setDevicePower(device, isOn: isOn)
            
            // Update local state
            updateDeviceState(deviceId: device.id, isOn: isOn)
            
            return true
        } catch let error as HomeKitError {
            self.error = error
            return false
        } catch {
            self.error = .operationFailed(error.localizedDescription)
            return false
        }
    }
    
    /// Clear the current error
    func clearError() {
        error = nil
    }
    
    /// Select a room for filtering
    func selectRoom(_ room: HomeRoom?) {
        selectedRoom = room
    }
    
    /// Get a device by ID
    func device(withId id: UUID) -> HomeDevice? {
        allDevices.first { $0.id == id }
    }
    
    // MARK: - Private Methods
    
    private func updateDeviceState(deviceId: UUID, isOn: Bool) {
        for roomIndex in rooms.indices {
            for deviceIndex in rooms[roomIndex].devices.indices {
                if rooms[roomIndex].devices[deviceIndex].id == deviceId {
                    rooms[roomIndex].devices[deviceIndex].isOn = isOn
                    return
                }
            }
        }
    }
}
