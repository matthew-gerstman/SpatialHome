import Foundation

/// Protocol for persisting device placements
protocol AnchorPersistenceServiceProtocol {
    /// Load all saved device placements
    func loadPlacements() throws -> [DevicePlacement]
    
    /// Save a device placement
    func savePlacement(_ placement: DevicePlacement) throws
    
    /// Delete a device placement
    func deletePlacement(id: UUID) throws
    
    /// Delete placement for a specific device
    func deletePlacement(forDeviceId deviceId: UUID) throws
    
    /// Update an existing placement
    func updatePlacement(_ placement: DevicePlacement) throws
    
    /// Check if a placement exists for a device
    func hasPlacement(forDeviceId deviceId: UUID) throws -> Bool
    
    /// Get placement for a specific device
    func getPlacement(forDeviceId deviceId: UUID) throws -> DevicePlacement?
    
    /// Delete all placements
    func deleteAllPlacements() throws
}

/// Errors that can occur during persistence operations
enum PersistenceError: Error, LocalizedError {
    case fileNotFound
    case encodingFailed(Error)
    case decodingFailed(Error)
    case writeFailed(Error)
    case placementNotFound
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Placements file not found."
        case .encodingFailed(let error):
            return "Failed to encode placements: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode placements: \(error.localizedDescription)"
        case .writeFailed(let error):
            return "Failed to write placements: \(error.localizedDescription)"
        case .placementNotFound:
            return "Placement not found."
        }
    }
}

/// File-based persistence service for device placements
final class AnchorPersistenceService: AnchorPersistenceServiceProtocol {
    
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    /// URL for the placements JSON file
    private var placementsFileURL: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent("device_placements.json")
    }
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    func loadPlacements() throws -> [DevicePlacement] {
        guard fileManager.fileExists(atPath: placementsFileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: placementsFileURL)
            let placements = try decoder.decode([DevicePlacement].self, from: data)
            return placements
        } catch let error as DecodingError {
            throw PersistenceError.decodingFailed(error)
        } catch {
            throw PersistenceError.decodingFailed(error)
        }
    }
    
    func savePlacement(_ placement: DevicePlacement) throws {
        var placements = try loadPlacements()
        
        // Remove existing placement for this device if it exists
        placements.removeAll { $0.deviceId == placement.deviceId }
        
        // Add new placement
        placements.append(placement)
        
        try writePlacements(placements)
    }
    
    func deletePlacement(id: UUID) throws {
        var placements = try loadPlacements()
        let originalCount = placements.count
        
        placements.removeAll { $0.id == id }
        
        if placements.count == originalCount {
            throw PersistenceError.placementNotFound
        }
        
        try writePlacements(placements)
    }
    
    func deletePlacement(forDeviceId deviceId: UUID) throws {
        var placements = try loadPlacements()
        let originalCount = placements.count
        
        placements.removeAll { $0.deviceId == deviceId }
        
        if placements.count == originalCount {
            throw PersistenceError.placementNotFound
        }
        
        try writePlacements(placements)
    }
    
    func updatePlacement(_ placement: DevicePlacement) throws {
        var placements = try loadPlacements()
        
        guard let index = placements.firstIndex(where: { $0.id == placement.id }) else {
            throw PersistenceError.placementNotFound
        }
        
        placements[index] = placement
        
        try writePlacements(placements)
    }
    
    func hasPlacement(forDeviceId deviceId: UUID) throws -> Bool {
        let placements = try loadPlacements()
        return placements.contains { $0.deviceId == deviceId }
    }
    
    func getPlacement(forDeviceId deviceId: UUID) throws -> DevicePlacement? {
        let placements = try loadPlacements()
        return placements.first { $0.deviceId == deviceId }
    }
    
    func deleteAllPlacements() throws {
        if fileManager.fileExists(atPath: placementsFileURL.path) {
            try fileManager.removeItem(at: placementsFileURL)
        }
    }
    
    // MARK: - Private Helpers
    
    private func writePlacements(_ placements: [DevicePlacement]) throws {
        do {
            let data = try encoder.encode(placements)
            try data.write(to: placementsFileURL, options: .atomic)
        } catch let error as EncodingError {
            throw PersistenceError.encodingFailed(error)
        } catch {
            throw PersistenceError.writeFailed(error)
        }
    }
}
