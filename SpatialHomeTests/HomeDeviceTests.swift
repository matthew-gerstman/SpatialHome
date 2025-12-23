import XCTest
@testable import SpatialHome

final class HomeDeviceTests: XCTestCase {
    
    func testDeviceInitialization() {
        let device = HomeDevice(
            name: "Living Room Lamp",
            roomName: "Living Room",
            type: .light,
            isOn: true
        )
        
        XCTAssertEqual(device.name, "Living Room Lamp")
        XCTAssertEqual(device.roomName, "Living Room")
        XCTAssertEqual(device.type, .light)
        XCTAssertTrue(device.isOn)
    }
    
    func testDeviceSupportsOnOff() {
        let light = HomeDevice(name: "Light", roomName: "Room", type: .light)
        let outlet = HomeDevice(name: "Outlet", roomName: "Room", type: .outlet)
        let switchDevice = HomeDevice(name: "Switch", roomName: "Room", type: .switch)
        let fan = HomeDevice(name: "Fan", roomName: "Room", type: .fan)
        let sensor = HomeDevice(name: "Sensor", roomName: "Room", type: .sensor)
        let lock = HomeDevice(name: "Lock", roomName: "Room", type: .lock)
        
        XCTAssertTrue(light.supportsOnOff)
        XCTAssertTrue(outlet.supportsOnOff)
        XCTAssertTrue(switchDevice.supportsOnOff)
        XCTAssertTrue(fan.supportsOnOff)
        XCTAssertFalse(sensor.supportsOnOff)
        XCTAssertFalse(lock.supportsOnOff)
    }
    
    func testDeviceIconNames() {
        XCTAssertEqual(HomeDevice(name: "Light", roomName: "Room", type: .light).iconName, "lightbulb.fill")
        XCTAssertEqual(HomeDevice(name: "Outlet", roomName: "Room", type: .outlet).iconName, "poweroutlet.type.b.fill")
        XCTAssertEqual(HomeDevice(name: "Switch", roomName: "Room", type: .switch).iconName, "light.switch.on.fill")
        XCTAssertEqual(HomeDevice(name: "Fan", roomName: "Room", type: .fan).iconName, "fan.fill")
    }
    
    func testDeviceCodable() throws {
        let device = HomeDevice(
            id: UUID(),
            name: "Test Device",
            roomName: "Test Room",
            type: .light,
            isOn: true
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(device)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HomeDevice.self, from: data)
        
        XCTAssertEqual(device.id, decoded.id)
        XCTAssertEqual(device.name, decoded.name)
        XCTAssertEqual(device.roomName, decoded.roomName)
        XCTAssertEqual(device.type, decoded.type)
        XCTAssertEqual(device.isOn, decoded.isOn)
    }
    
    func testDeviceEquality() {
        let id = UUID()
        let device1 = HomeDevice(id: id, name: "Light", roomName: "Room", type: .light, isOn: true)
        let device2 = HomeDevice(id: id, name: "Light", roomName: "Room", type: .light, isOn: true)
        let device3 = HomeDevice(id: UUID(), name: "Light", roomName: "Room", type: .light, isOn: true)
        
        XCTAssertEqual(device1, device2)
        XCTAssertNotEqual(device1, device3)
    }
}
