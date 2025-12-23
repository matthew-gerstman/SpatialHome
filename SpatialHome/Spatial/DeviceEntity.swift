import RealityKit
import SwiftUI

/// A RealityKit entity representing a placed HomeKit device
class DeviceEntity: Entity, HasModel, HasCollision {
    
    /// The device this entity represents
    var device: HomeDevice
    
    /// The placement data for this entity
    var placement: DevicePlacement
    
    /// Whether the device is currently on
    var isOn: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    /// Callback when the entity is tapped
    var onTap: ((DeviceEntity) async -> Void)?
    
    // MARK: - Initialization
    
    required init() {
        self.device = HomeDevice(name: "", roomName: "", type: .other)
        self.placement = DevicePlacement(deviceId: UUID(), anchor: SpatialAnchor(position: .zero))
        self.isOn = false
        super.init()
    }
    
    init(device: HomeDevice, placement: DevicePlacement, onTap: ((DeviceEntity) async -> Void)? = nil) {
        self.device = device
        self.placement = placement
        self.isOn = device.isOn
        self.onTap = onTap
        
        super.init()
        
        setupEntity()
    }
    
    // MARK: - Setup
    
    private func setupEntity() {
        // Create the visual representation
        let mesh = MeshResource.generateSphere(radius: 0.05)
        let material = createMaterial()
        
        self.model = ModelComponent(mesh: mesh, materials: [material])
        
        // Add collision for interaction
        let shape = ShapeResource.generateSphere(radius: 0.06)
        self.collision = CollisionComponent(shapes: [shape])
        
        // Enable input targeting
        self.components.set(InputTargetComponent())
        
        // Position from placement
        self.position = placement.anchor.position
        
        // Add label
        addLabel()
    }
    
    private func createMaterial() -> SimpleMaterial {
        let color: UIColor = isOn ? .systemYellow : .systemGray
        var material = SimpleMaterial()
        material.color = .init(tint: color.withAlphaComponent(0.8))
        material.roughness = 0.3
        material.metallic = 0.1
        return material
    }
    
    private func addLabel() {
        // Create a text entity for the device name
        let textMesh = MeshResource.generateText(
            device.name,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.015),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        
        // Position label above the sphere
        textEntity.position = [0, 0.08, 0]
        
        // Make label face the user (billboard effect would need updating)
        addChild(textEntity)
    }
    
    // MARK: - State Updates
    
    func updateAppearance() {
        let material = createMaterial()
        self.model?.materials = [material]
    }
    
    func updatePosition(_ newPosition: SIMD3<Float>) {
        self.position = newPosition
        placement.updatePosition(newPosition)
    }
    
    // MARK: - Interaction
    
    func handleTap() async {
        await onTap?(self)
    }
}

// MARK: - Entity Component for tracking
struct DeviceComponent: Component {
    let deviceId: UUID
    let placementId: UUID
}
