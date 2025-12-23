import Foundation
import HomeKit

/// Protocol defining HomeKit operations
protocol HomeKitServiceProtocol {
    /// Fetch all rooms and their devices from HomeKit
    func fetchRoomsAndDevices() async throws -> [HomeRoom]
    
    /// Toggle a device's power state
    func toggleDevice(_ device: HomeDevice) async throws -> Bool
    
    /// Set a device's power state explicitly
    func setDevicePower(_ device: HomeDevice, isOn: Bool) async throws
    
    /// Get current power state for a device
    func getDevicePowerState(_ device: HomeDevice) async throws -> Bool
    
    /// Request HomeKit authorization
    func requestAuthorization() async throws
}

/// Errors that can occur during HomeKit operations
enum HomeKitError: Error, LocalizedError {
    case notAuthorized
    case homeNotFound
    case deviceNotFound
    case characteristicNotFound
    case controlNotSupported
    case operationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "HomeKit access not authorized. Please grant access in Settings."
        case .homeNotFound:
            return "No HomeKit home found. Please set up a home in the Home app."
        case .deviceNotFound:
            return "Device not found in HomeKit."
        case .characteristicNotFound:
            return "Power control characteristic not found for this device."
        case .controlNotSupported:
            return "This device does not support on/off control."
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        }
    }
}

/// Real HomeKit service implementation
final class HomeKitService: NSObject, HomeKitServiceProtocol {
    private let homeManager: HMHomeManager
    private var authorizationContinuation: CheckedContinuation<Void, Error>?
    private var isAuthorized = false
    
    override init() {
        self.homeManager = HMHomeManager()
        super.init()
        self.homeManager.delegate = self
    }
    
    func requestAuthorization() async throws {
        // HomeKit authorization happens automatically when HMHomeManager is created
        // We wait for the delegate callback
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            if isAuthorized {
                continuation.resume()
            } else {
                self.authorizationContinuation = continuation
            }
        }
    }
    
    func fetchRoomsAndDevices() async throws -> [HomeRoom] {
        guard let home = homeManager.primaryHome else {
            throw HomeKitError.homeNotFound
        }
        
        var rooms: [HomeRoom] = []
        
        for hmRoom in home.rooms {
            let room = HomeRoom(from: hmRoom, accessories: home.accessories)
            
            // Fetch current power states for each device
            var updatedDevices: [HomeDevice] = []
            for var device in room.devices {
                if device.supportsOnOff {
                    do {
                        device.isOn = try await getDevicePowerState(device)
                    } catch {
                        // If we can't get the state, leave it as default (false)
                    }
                }
                updatedDevices.append(device)
            }
            
            var updatedRoom = room
            updatedRoom.devices = updatedDevices
            rooms.append(updatedRoom)
        }
        
        // Also include devices not assigned to a room
        let unassignedAccessories = home.accessories.filter { $0.room == nil }
        if !unassignedAccessories.isEmpty {
            var unassignedDevices = unassignedAccessories.map { HomeDevice(from: $0) }
            
            // Fetch power states
            for i in unassignedDevices.indices {
                if unassignedDevices[i].supportsOnOff {
                    do {
                        unassignedDevices[i].isOn = try await getDevicePowerState(unassignedDevices[i])
                    } catch {
                        // Leave as default
                    }
                }
            }
            
            let unassignedRoom = HomeRoom(name: "Unassigned", devices: unassignedDevices)
            rooms.append(unassignedRoom)
        }
        
        return rooms
    }
    
    func toggleDevice(_ device: HomeDevice) async throws -> Bool {
        let currentState = try await getDevicePowerState(device)
        let newState = !currentState
        try await setDevicePower(device, isOn: newState)
        return newState
    }
    
    func setDevicePower(_ device: HomeDevice, isOn: Bool) async throws {
        guard device.supportsOnOff else {
            throw HomeKitError.controlNotSupported
        }
        
        let characteristic = try await findPowerCharacteristic(for: device)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            characteristic.writeValue(isOn) { error in
                if let error = error {
                    continuation.resume(throwing: HomeKitError.operationFailed(error.localizedDescription))
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func getDevicePowerState(_ device: HomeDevice) async throws -> Bool {
        let characteristic = try await findPowerCharacteristic(for: device)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            characteristic.readValue { error in
                if let error = error {
                    continuation.resume(throwing: HomeKitError.operationFailed(error.localizedDescription))
                } else if let value = characteristic.value as? Bool {
                    continuation.resume(returning: value)
                } else if let value = characteristic.value as? Int {
                    continuation.resume(returning: value != 0)
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func findPowerCharacteristic(for device: HomeDevice) async throws -> HMCharacteristic {
        guard let home = homeManager.primaryHome else {
            throw HomeKitError.homeNotFound
        }
        
        guard let accessory = home.accessories.first(where: { 
            UUID(uuidString: $0.uniqueIdentifier.uuidString) == device.id 
        }) else {
            throw HomeKitError.deviceNotFound
        }
        
        // Find the power state characteristic
        for service in accessory.services {
            for characteristic in service.characteristics {
                if characteristic.characteristicType == HMCharacteristicTypePowerState {
                    return characteristic
                }
            }
        }
        
        throw HomeKitError.characteristicNotFound
    }
}

// MARK: - HMHomeManagerDelegate
extension HomeKitService: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        isAuthorized = true
        authorizationContinuation?.resume()
        authorizationContinuation = nil
    }
    
    func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
        if status.contains(.authorized) {
            isAuthorized = true
            authorizationContinuation?.resume()
            authorizationContinuation = nil
        }
    }
}
