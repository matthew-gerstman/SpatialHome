import XCTest
import simd
@testable import SpatialHome

@MainActor
final class HomeViewModelTests: XCTestCase {
    
    var viewModel: HomeViewModel!
    var mockService: MockHomeKitService!
    
    override func setUp() async throws {
        mockService = MockHomeKitService()
        viewModel = HomeViewModel(homeKitService: mockService)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockService = nil
    }
    
    func testFetchDevices() async {
        await viewModel.fetchDevices()
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.rooms.count, 4)
        XCTAssertEqual(mockService.fetchCallCount, 1)
    }
    
    func testFetchDevicesFailure() async {
        mockService.shouldFailFetch = true
        
        await viewModel.fetchDevices()
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.rooms.isEmpty)
    }
    
    func testAllDevices() async {
        await viewModel.fetchDevices()
        
        XCTAssertEqual(viewModel.allDevices.count, 13)
    }
    
    func testFilteredDevicesWithSearch() async {
        await viewModel.fetchDevices()
        
        viewModel.searchText = "Light"
        
        XCTAssertTrue(viewModel.filteredDevices.allSatisfy { 
            $0.name.contains("Light") || $0.roomName.contains("Light")
        })
    }
    
    func testFilteredDevicesByRoom() async {
        await viewModel.fetchDevices()
        
        let livingRoom = viewModel.rooms.first { $0.name == "Living Room" }
        viewModel.selectRoom(livingRoom)
        
        XCTAssertEqual(viewModel.filteredDevices.count, livingRoom?.devices.count)
    }
    
    func testToggleDevice() async {
        await viewModel.fetchDevices()
        
        let device = viewModel.allDevices.first!
        let originalState = device.isOn
        
        let newState = await viewModel.toggleDevice(device)
        
        XCTAssertNotNil(newState)
        XCTAssertNotEqual(newState, originalState)
    }
    
    func testDeviceCount() async {
        await viewModel.fetchDevices()
        
        XCTAssertEqual(viewModel.totalDeviceCount, 13)
        XCTAssertGreaterThan(viewModel.onDeviceCount, 0)
    }
    
    func testClearError() async {
        mockService.shouldFailFetch = true
        await viewModel.fetchDevices()
        
        XCTAssertNotNil(viewModel.error)
        
        viewModel.clearError()
        
        XCTAssertNil(viewModel.error)
    }
}

@MainActor
final class SpatialPlacementViewModelTests: XCTestCase {
    
    var viewModel: SpatialPlacementViewModel!
    var mockService: MockAnchorPersistenceService!
    
    override func setUp() async throws {
        mockService = MockAnchorPersistenceService()
        viewModel = SpatialPlacementViewModel(persistenceService: mockService)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockService = nil
    }
    
    func testLoadPlacements() {
        mockService.addSamplePlacements()
        
        viewModel.loadPlacements()
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.placements.count, 3)
    }
    
    func testPlaceDevice() {
        let device = HomeDevice(name: "Test Light", roomName: "Room", type: .light)
        let position = SIMD3<Float>(1, 2, 3)
        
        let placement = viewModel.placeDevice(device, at: position)
        
        XCTAssertNotNil(placement)
        XCTAssertEqual(placement?.deviceId, device.id)
        XCTAssertEqual(viewModel.placements.count, 1)
    }
    
    func testUpdatePlacementPosition() {
        let device = HomeDevice(name: "Test Light", roomName: "Room", type: .light)
        let placement = viewModel.placeDevice(device, at: SIMD3<Float>(0, 0, 0))!
        
        let success = viewModel.updatePlacementPosition(placement, to: SIMD3<Float>(5, 5, 5))
        
        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.placements.first?.anchor.position.x, 5.0, accuracy: 0.001)
    }
    
    func testRemovePlacement() {
        let device = HomeDevice(name: "Test Light", roomName: "Room", type: .light)
        _ = viewModel.placeDevice(device, at: SIMD3<Float>(0, 0, 0))
        
        let success = viewModel.removePlacement(forDeviceId: device.id)
        
        XCTAssertTrue(success)
        XCTAssertTrue(viewModel.placements.isEmpty)
    }
    
    func testIsDevicePlaced() {
        let device = HomeDevice(name: "Test Light", roomName: "Room", type: .light)
        
        XCTAssertFalse(viewModel.isDevicePlaced(device))
        
        _ = viewModel.placeDevice(device, at: SIMD3<Float>(0, 0, 0))
        
        XCTAssertTrue(viewModel.isDevicePlaced(device))
    }
    
    func testClearAllPlacements() {
        mockService.addSamplePlacements()
        viewModel.loadPlacements()
        
        XCTAssertGreaterThan(viewModel.placements.count, 0)
        
        let success = viewModel.clearAllPlacements()
        
        XCTAssertTrue(success)
        XCTAssertTrue(viewModel.placements.isEmpty)
    }
}

@MainActor
final class DeviceControlViewModelTests: XCTestCase {
    
    var viewModel: DeviceControlViewModel!
    var mockService: MockHomeKitService!
    var testDevice: HomeDevice!
    
    override func setUp() async throws {
        mockService = MockHomeKitService()
        testDevice = HomeDevice(name: "Test Light", roomName: "Room", type: .light, isOn: false)
        viewModel = DeviceControlViewModel(device: testDevice, homeKitService: mockService)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockService = nil
        testDevice = nil
    }
    
    func testInitialState() {
        XCTAssertFalse(viewModel.isOn)
        XCTAssertFalse(viewModel.isToggling)
        XCTAssertNil(viewModel.error)
    }
    
    func testCanControl() {
        XCTAssertTrue(viewModel.canControl)
        
        // Sensor can't be controlled
        let sensor = HomeDevice(name: "Sensor", roomName: "Room", type: .sensor)
        let sensorVM = DeviceControlViewModel(device: sensor, homeKitService: mockService)
        XCTAssertFalse(sensorVM.canControl)
    }
    
    func testToggle() async {
        // Add device to mock service first
        mockService.mockRooms = [HomeRoom(name: "Room", devices: [testDevice])]
        
        await viewModel.toggle()
        
        XCTAssertFalse(viewModel.isToggling)
        XCTAssertTrue(viewModel.isOn)
        XCTAssertNotNil(viewModel.lastToggleTime)
    }
    
    func testTurnOn() async {
        mockService.mockRooms = [HomeRoom(name: "Room", devices: [testDevice])]
        
        await viewModel.turnOn()
        
        XCTAssertTrue(viewModel.isOn)
    }
    
    func testTurnOff() async {
        testDevice.isOn = true
        viewModel = DeviceControlViewModel(device: testDevice, homeKitService: mockService)
        mockService.mockRooms = [HomeRoom(name: "Room", devices: [testDevice])]
        
        await viewModel.turnOff()
        
        XCTAssertFalse(viewModel.isOn)
    }
    
    func testToggleFailure() async {
        mockService.shouldFailToggle = true
        
        await viewModel.toggle()
        
        XCTAssertNotNil(viewModel.error)
    }
    
    func testClearError() async {
        mockService.shouldFailToggle = true
        await viewModel.toggle()
        
        XCTAssertNotNil(viewModel.error)
        
        viewModel.clearError()
        
        XCTAssertNil(viewModel.error)
    }
}
