import Foundation

enum MachineStatus: String, Codable, CaseIterable, Identifiable {
    case ready = "Einsatzbereit", limited = "Eingeschränkt", blocked = "Gesperrt"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .ready: return "checkmark.circle.fill"
        case .limited: return "exclamationmark.triangle.fill"
        case .blocked: return "xmark.octagon.fill"
        }
    }
}

struct Machine: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var category = "Traktor"
    var manufacturer = ""
    var model = ""
    var serialNumber = ""
    var location = ""
    var notes = ""
    var status: MachineStatus = .ready
    var photo: Data?
    var qrPayload: String { "hofpilot://machine/\(id.uuidString)" }
    static let categories = ["Traktor", "Anhänger", "Mähdrescher", "Gabelstapler", "Bewässerung", "Fahrzeug", "Sonstiges"]
    var symbol: String { category == "Traktor" ? "leaf.fill" : "wrench.and.screwdriver.fill" }
}

struct FarmTask: Identifiable, Codable, Hashable {
    var id = UUID()
    var machineID: UUID
    var title: String
    var date: Date
    var notes = ""
    var isCompleted = false
    var calendarExportedAt: Date?
}

struct FarmData: Codable {
    var schemaVersion = 1
    var farmName = "Mein Hof"
    var machines: [Machine] = []
    var tasks: [FarmTask] = []
}

enum MachineLink {
    static func id(from value: String) -> UUID? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = UUID(uuidString: trimmed) { return id }
        guard let url = URL(string: trimmed), url.scheme == "hofpilot",
              url.host == "machine", url.pathComponents.count == 2 else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
}
