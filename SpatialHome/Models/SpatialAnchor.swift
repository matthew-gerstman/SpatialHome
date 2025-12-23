import Foundation
import ARKit

/// Represents a spatial position in the user's physical space
struct SpatialAnchor: Codable, Equatable {
    let id: UUID
    
    /// Position in 3D space (x, y, z)
    var position: SIMD3<Float>
    
    /// Rotation quaternion (x, y, z, w)
    var rotation: simd_quatf
    
    init(id: UUID = UUID(), position: SIMD3<Float>, rotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])) {
        self.id = id
        self.position = position
        self.rotation = rotation
    }
    
    /// Create from ARKit ARAnchor
    init(from anchor: ARAnchor) {
        self.id = anchor.identifier
        self.position = SIMD3<Float>(anchor.transform.columns.3.x,
                                     anchor.transform.columns.3.y,
                                     anchor.transform.columns.3.z)
        self.rotation = simd_quatf(anchor.transform)
    }
    
    /// Convert to 4x4 transform matrix
    var transform: simd_float4x4 {
        var matrix = simd_float4x4(rotation)
        matrix.columns.3 = SIMD4<Float>(position.x, position.y, position.z, 1.0)
        return matrix
    }
}

// MARK: - Codable conformance for SIMD types
extension SpatialAnchor {
    enum CodingKeys: String, CodingKey {
        case id, position, rotation
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        
        let posArray = try container.decode([Float].self, forKey: .position)
        guard posArray.count == 3 else {
            throw DecodingError.dataCorruptedError(forKey: .position, in: container, debugDescription: "Position must have 3 components")
        }
        position = SIMD3<Float>(posArray[0], posArray[1], posArray[2])
        
        let rotArray = try container.decode([Float].self, forKey: .rotation)
        guard rotArray.count == 4 else {
            throw DecodingError.dataCorruptedError(forKey: .rotation, in: container, debugDescription: "Rotation must have 4 components")
        }
        rotation = simd_quatf(ix: rotArray[0], iy: rotArray[1], iz: rotArray[2], r: rotArray[3])
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode([position.x, position.y, position.z], forKey: .position)
        try container.encode([rotation.imag.x, rotation.imag.y, rotation.imag.z, rotation.real], forKey: .rotation)
    }
}
