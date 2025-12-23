import XCTest
@testable import SpatialHome

final class HomeRoomTests: XCTestCase {
    
    func testRoomInitialization() {
        let devices = [
            HomeDevice(name: "Light 1", roomName: "Living Room", type: .light, isOn: true),
            HomeDevice(name: "Light 2", roomName: "Living Room", type: .light, isOn: false)
        ]
        
        let room = HomeRoom(name: "Living Room", devices: devices)
        
        XCTAssertEqual(room.name, "Living Room")
        XCTAssertEqual(room.devices.count, 2)
    }
    
    func testDeviceCount() {
        let devices = [
            HomeDevice(name: "Light 1", roomName: "Room", type: .light),
            HomeDevice(name: "Light 2", roomName: "Room", type: .light),
            HomeDevice(name: "Outlet", roomName: "Room", type: .outlet)
        ]
        
        let room = HomeRoom(name: "Room", devices: devices)
        XCTAssertEqual(room.deviceCount, 3)
    }
    
    func testOnDeviceCount() {
        let devices = [
            HomeDevice(name: "Light 1", roomName: "Room", type: .light, isOn: true),
            HomeDevice(name: "Light 2", roomName: "Room", type: .light, isOn: false),
            HomeDevice(name: "Outlet", roomName: "Room", type: .outlet, isOn: true)
        ]
        
        let room = HomeRoom(name: "Room", devices: devices)
        XCTAssertEqual(room.onDeviceCount, 2)
    }
    
    func testHasDevicesOn() {
        let roomWithDevicesOn = HomeRoom(
            name: "Room 1",
            devices: [
                HomeDevice(name: "Light", roomName: "Room 1", type: .light, isOn: true)
            ]
        )
        
        let roomWithDevicesOff = HomeRoom(
            name: "Room 2",
            devices: [
                HomeDevice(name: "Light", roomName: "Room 2", type: .light, isOn: false)
            ]
        )
        
        let emptyRoom = HomeRoom(name: "Room 3", devices: [])
        
        XCTAssertTrue(roomWithDevicesOn.hasDevicesOn)
        XCTAssertFalse(roomWithDevicesOff.hasDevicesOn)
        XCTAssertFalse(emptyRoom.hasDevicesOn)
    }
    
    func testRoomCodable() throws {
        let devices = [
            HomeDevice(name: "Light", roomName: "Room", type: .light, isOn: true)
        ]
        let room = HomeRoom(id: UUID(), name: "Test Room", devices: devices)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(room)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HomeRoom.self, from: data)
        
        XCTAssertEqual(room.id, decoded.id)
        XCTAssertEqual(room.name, decoded.name)
        XCTAssertEqual(room.devices.count, decoded.devices.count)
    }
    
    func testRoomEquality() {
        let id = UUID()
        let devices = [HomeDevice(name: "Light", roomName: "Room", type: .light)]
        
        let room1 = HomeRoom(id: id, name: "Room", devices: devices)
        let room2 = HomeRoom(id: id, name: "Room", devices: devices)
        let room3 = HomeRoom(id: UUID(), name: "Room", devices: devices)
        
        XCTAssertEqual(room1, room2)
        XCTAssertNotEqual(room1, room3)
    }
}
