import Foundation
import HomeKit

/// Represents a HomeKit room containing devices
struct HomeRoom: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    var devices: [HomeDevice]
    
    init(id: UUID = UUID(), name: String, devices: [HomeDevice] = []) {
        self.id = id
        self.name = name
        self.devices = devices
    }
    
    /// Create from HMRoom
    init(from room: HMRoom, accessories: [HMAccessory]) {
        self.id = UUID(uuidString: room.uniqueIdentifier.uuidString) ?? UUID()
        self.name = room.name
        
        // Filter accessories that belong to this room
        let roomAccessories = accessories.filter { $0.room?.uniqueIdentifier == room.uniqueIdentifier }
        self.devices = roomAccessories.map { HomeDevice(from: $0) }
    }
    
    /// Number of devices in this room
    var deviceCount: Int {
        devices.count
    }
    
    /// Number of devices currently on
    var onDeviceCount: Int {
        devices.filter { $0.isOn }.count
    }
    
    /// Whether any devices in this room are on
    var hasDevicesOn: Bool {
        devices.contains { $0.isOn }
    }
}
