import Foundation
import Combine

/// View model for controlling a single device with loading states
@MainActor
final class DeviceControlViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var device: HomeDevice
    @Published private(set) var isToggling = false
    @Published private(set) var error: HomeKitError?
    @Published private(set) var lastToggleTime: Date?
    
    // MARK: - Computed Properties
    
    /// Whether the device is currently on
    var isOn: Bool {
        device.isOn
    }
    
    /// Whether the device can be controlled
    var canControl: Bool {
        device.supportsOnOff && !isToggling
    }
    
    /// Icon for the current state
    var stateIcon: String {
        device.isOn ? device.iconName : device.iconName.replacingOccurrences(of: ".fill", with: "")
    }
    
    // MARK: - Dependencies
    
    private let homeKitService: HomeKitServiceProtocol
    
    // MARK: - Initialization
    
    init(device: HomeDevice, homeKitService: HomeKitServiceProtocol) {
        self.device = device
        self.homeKitService = homeKitService
    }
    
    // MARK: - Public Methods
    
    /// Toggle the device power state
    func toggle() async {
        guard canControl else { return }
        
        isToggling = true
        error = nil
        
        do {
            let newState = try await homeKitService.toggleDevice(device)
            device.isOn = newState
            lastToggleTime = Date()
        } catch let error as HomeKitError {
            self.error = error
        } catch {
            self.error = .operationFailed(error.localizedDescription)
        }
        
        isToggling = false
    }
    
    /// Turn the device on
    func turnOn() async {
        guard canControl else { return }
        
        isToggling = true
        error = nil
        
        do {
            try await homeKitService.setDevicePower(device, isOn: true)
            device.isOn = true
            lastToggleTime = Date()
        } catch let error as HomeKitError {
            self.error = error
        } catch {
            self.error = .operationFailed(error.localizedDescription)
        }
        
        isToggling = false
    }
    
    /// Turn the device off
    func turnOff() async {
        guard canControl else { return }
        
        isToggling = true
        error = nil
        
        do {
            try await homeKitService.setDevicePower(device, isOn: false)
            device.isOn = false
            lastToggleTime = Date()
        } catch let error as HomeKitError {
            self.error = error
        } catch {
            self.error = .operationFailed(error.localizedDescription)
        }
        
        isToggling = false
    }
    
    /// Refresh the device state from HomeKit
    func refreshState() async {
        guard device.supportsOnOff else { return }
        
        do {
            let currentState = try await homeKitService.getDevicePowerState(device)
            device.isOn = currentState
        } catch {
            // Silently fail refresh - not critical
        }
    }
    
    /// Update the device (e.g., after external changes)
    func updateDevice(_ newDevice: HomeDevice) {
        device = newDevice
    }
    
    /// Clear the current error
    func clearError() {
        error = nil
    }
}
