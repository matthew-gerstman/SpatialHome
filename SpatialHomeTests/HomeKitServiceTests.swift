import XCTest
@testable import SpatialHome

final class HomeKitServiceTests: XCTestCase {
    
    var mockService: MockHomeKitService!
    
    override func setUp() {
        super.setUp()
        mockService = MockHomeKitService()
    }
    
    override func tearDown() {
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - Authorization Tests
    
    func testRequestAuthorizationSuccess() async throws {
        mockService.shouldFailAuthorization = false
        
        // Should not throw
        try await mockService.requestAuthorization()
    }
    
    func testRequestAuthorizationFailure() async {
        mockService.shouldFailAuthorization = true
        
        do {
            try await mockService.requestAuthorization()
            XCTFail("Expected authorization to fail")
        } catch let error as HomeKitError {
            XCTAssertEqual(error, .notAuthorized)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Fetch Tests
    
    func testFetchRoomsAndDevicesSuccess() async throws {
        let rooms = try await mockService.fetchRoomsAndDevices()
        
        XCTAssertEqual(rooms.count, 4)
        XCTAssertEqual(mockService.fetchCallCount, 1)
        
        // Verify room names
        let roomNames = rooms.map { $0.name }
        XCTAssertTrue(roomNames.contains("Living Room"))
        XCTAssertTrue(roomNames.contains("Bedroom"))
        XCTAssertTrue(roomNames.contains("Kitchen"))
        XCTAssertTrue(roomNames.contains("Office"))
    }
    
    func testFetchRoomsAndDevicesFailure() async {
        mockService.shouldFailFetch = true
        
        do {
            _ = try await mockService.fetchRoomsAndDevices()
            XCTFail("Expected fetch to fail")
        } catch let error as HomeKitError {
            XCTAssertEqual(error, .homeNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testFetchReturnsDevicesWithCorrectTypes() async throws {
        let rooms = try await mockService.fetchRoomsAndDevices()
        
        let livingRoom = rooms.first { $0.name == "Living Room" }
        XCTAssertNotNil(livingRoom)
        
        let devices = livingRoom!.devices
        XCTAssertTrue(devices.contains { $0.type == .light })
        XCTAssertTrue(devices.contains { $0.type == .outlet })
        XCTAssertTrue(devices.contains { $0.type == .fan })
    }
    
    // MARK: - Toggle Tests
    
    func testToggleDeviceSuccess() async throws {
        let rooms = try await mockService.fetchRoomsAndDevices()
        let device = rooms[0].devices[0] // Ceiling Light, initially on
        
        XCTAssertTrue(device.isOn)
        
        let newState = try await mockService.toggleDevice(device)
        
        XCTAssertFalse(newState)
        XCTAssertEqual(mockService.toggleCallCount, 1)
    }
    
    func testToggleDeviceFailure() async throws {
        let rooms = try await mockService.fetchRoomsAndDevices()
        let device = rooms[0].devices[0]
        
        mockService.shouldFailToggle = true
        
        do {
            _ = try await mockService.toggleDevice(device)
            XCTFail("Expected toggle to fail")
        } catch let error as HomeKitError {
            if case .operationFailed(_) = error {
                // Expected
            } else {
                XCTFail("Expected operationFailed error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testToggleUpdatesDeviceState() async throws {
        let rooms = try await mockService.fetchRoomsAndDevices()
        var device = rooms[0].devices[1] // Floor Lamp, initially off
        
        XCTAssertFalse(device.isOn)
        
        // Toggle on
        device.isOn = try await mockService.toggleDevice(device)
        XCTAssertTrue(device.isOn)
        
        // Toggle off
        device.isOn = try await mockService.toggleDevice(device)
        XCTAssertFalse(device.isOn)
    }
    
    // MARK: - Set Power Tests
    
    func testSetDevicePowerOn() async throws {
        let rooms = try await mockService.fetchRoomsAndDevices()
        let device = rooms[0].devices[1] // Floor Lamp, initially off
        
        try await mockService.setDevicePower(device, isOn: true)
        
        let newState = try await mockService.getDevicePowerState(device)
        XCTAssertTrue(newState)
        XCTAssertEqual(mockService.setDevicePowerCallCount, 1)
    }
    
    func testSetDevicePowerOff() async throws {
        let rooms = try await mockService.fetchRoomsAndDevices()
        let device = rooms[0].devices[0] // Ceiling Light, initially on
        
        try await mockService.setDevicePower(device, isOn: false)
        
        let newState = try await mockService.getDevicePowerState(device)
        XCTAssertFalse(newState)
    }
    
    func testSetDevicePowerUnsupportedDevice() async throws {
        // Create a sensor device which doesn't support on/off
        let sensor = HomeDevice(name: "Motion Sensor", roomName: "Room", type: .sensor)
        
        do {
            try await mockService.setDevicePower(sensor, isOn: true)
            XCTFail("Expected controlNotSupported error")
        } catch let error as HomeKitError {
            XCTAssertEqual(error, .controlNotSupported)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Get Power State Tests
    
    func testGetDevicePowerState() async throws {
        let rooms = try await mockService.fetchRoomsAndDevices()
        
        // Ceiling Light is initially on
        let onDevice = rooms[0].devices[0]
        let onState = try await mockService.getDevicePowerState(onDevice)
        XCTAssertTrue(onState)
        
        // Floor Lamp is initially off
        let offDevice = rooms[0].devices[1]
        let offState = try await mockService.getDevicePowerState(offDevice)
        XCTAssertFalse(offState)
    }
    
    func testGetDevicePowerStateNotFound() async {
        let unknownDevice = HomeDevice(name: "Unknown", roomName: "Room", type: .light)
        
        do {
            _ = try await mockService.getDevicePowerState(unknownDevice)
            XCTFail("Expected deviceNotFound error")
        } catch let error as HomeKitError {
            XCTAssertEqual(error, .deviceNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Reset Tests
    
    func testReset() async throws {
        // Make some changes
        _ = try await mockService.fetchRoomsAndDevices()
        mockService.shouldFailFetch = true
        
        XCTAssertEqual(mockService.fetchCallCount, 1)
        XCTAssertTrue(mockService.shouldFailFetch)
        
        // Reset
        mockService.reset()
        
        XCTAssertEqual(mockService.fetchCallCount, 0)
        XCTAssertFalse(mockService.shouldFailFetch)
    }
}

// MARK: - HomeKitError Equatable
extension HomeKitError: Equatable {
    public static func == (lhs: HomeKitError, rhs: HomeKitError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthorized, .notAuthorized),
             (.homeNotFound, .homeNotFound),
             (.deviceNotFound, .deviceNotFound),
             (.characteristicNotFound, .characteristicNotFound),
             (.controlNotSupported, .controlNotSupported):
            return true
        case (.operationFailed(let lhsMsg), .operationFailed(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}
