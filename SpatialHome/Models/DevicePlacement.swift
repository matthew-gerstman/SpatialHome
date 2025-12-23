import Foundation

/// Links a HomeKit device to a spatial location in the user's space
struct DevicePlacement: Identifiable, Codable, Equatable {
    let id: UUID
    let deviceId: UUID
    var anchor: SpatialAnchor
    let createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), deviceId: UUID, anchor: SpatialAnchor, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.deviceId = deviceId
        self.anchor = anchor
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Update the spatial position
    mutating func updatePosition(_ position: SIMD3<Float>) {
        anchor.position = position
        updatedAt = Date()
    }
    
    /// Update the spatial rotation
    mutating func updateRotation(_ rotation: simd_quatf) {
        anchor.rotation = rotation
        updatedAt = Date()
    }
    
    /// Update both position and rotation
    mutating func updateTransform(position: SIMD3<Float>, rotation: simd_quatf) {
        anchor.position = position
        anchor.rotation = rotation
        updatedAt = Date()
    }
}
