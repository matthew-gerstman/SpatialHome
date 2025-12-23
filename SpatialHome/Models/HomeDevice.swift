import Foundation
import HomeKit

/// Represents a HomeKit device with its essential properties
struct HomeDevice: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let roomName: String
    let type: DeviceType
    var isOn: Bool
    
    /// The type of HomeKit device
    enum DeviceType: String, Codable {
        case light
        case outlet
        case `switch`
        case fan
        case thermostat
        case lock
        case garageDoor
        case sensor
        case other
        
        /// Initialize from HMAccessory service type
        init(from serviceType: String) {
            switch serviceType {
            case HMServiceTypeLightbulb:
                self = .light
            case HMServiceTypeOutlet:
                self = .outlet
            case HMServiceTypeSwitch:
                self = .switch
            case HMServiceTypeFan:
                self = .fan
            case HMServiceTypeThermostat:
                self = .thermostat
            case HMServiceTypeLockMechanism:
                self = .lock
            case HMServiceTypeGarageDoorOpener:
                self = .garageDoor
            case HMServiceTypeMotionSensor, HMServiceTypeContactSensor,
                 HMServiceTypeTemperatureSensor, HMServiceTypeHumiditySensor:
                self = .sensor
            default:
                self = .other
            }
        }
    }
    
    init(id: UUID = UUID(), name: String, roomName: String, type: DeviceType, isOn: Bool = false) {
        self.id = id
        self.name = name
        self.roomName = roomName
        self.type = type
        self.isOn = isOn
    }
    
    /// Create from HMAccessory
    init(from accessory: HMAccessory) {
        self.id = UUID(uuidString: accessory.uniqueIdentifier.uuidString) ?? UUID()
        self.name = accessory.name
        self.roomName = accessory.room?.name ?? "Unknown Room"
        
        // Determine type from primary service
        if let primaryService = accessory.services.first {
            self.type = DeviceType(from: primaryService.serviceType)
        } else {
            self.type = .other
        }
        
        // Determine on/off state from power state characteristic
        self.isOn = false // Will be updated by service layer
    }
    
    /// Whether this device type supports on/off control
    var supportsOnOff: Bool {
        switch type {
        case .light, .outlet, .switch, .fan:
            return true
        case .thermostat, .lock, .garageDoor, .sensor, .other:
            return false
        }
    }
    
    /// SF Symbol name for this device type
    var iconName: String {
        switch type {
        case .light:
            return "lightbulb.fill"
        case .outlet:
            return "poweroutlet.type.b.fill"
        case .switch:
            return "light.switch.on.fill"
        case .fan:
            return "fan.fill"
        case .thermostat:
            return "thermometer.medium"
        case .lock:
            return "lock.fill"
        case .garageDoor:
            return "garage.closed"
        case .sensor:
            return "sensor.fill"
        case .other:
            return "questionmark.circle.fill"
        }
    }
}
