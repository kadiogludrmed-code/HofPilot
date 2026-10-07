import SwiftUI

@MainActor
final class FarmStore: ObservableObject {
    @Published private(set) var data = FarmData()
    @Published var errorMessage: String?
    @Published private(set) var storageAvailable = true
    private let fileURL: URL
    static let freeMachineLimit = 20

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? URL.applicationSupportDirectory
            .appendingPathComponent("HofPilot", isDirectory: true)
            .appendingPathComponent("farm-v1.json")
        guard FileManager.default.fileExists(atPath: self.fileURL.path) else { return }
        do {
            let decoded = try JSONDecoder().decode(FarmData.self, from: Data(contentsOf: self.fileURL))
            guard decoded.schemaVersion == 1 else {
                throw CocoaError(.fileReadCorruptFile)
            }
            data = decoded
        } catch {
            storageAvailable = false
            errorMessage = "Die gespeicherten Daten konnten nicht geladen werden. Sie werden nicht überschrieben. Bitte sichere die App-Daten, bevor du die App neu installierst."
        }
    }

    var pendingTasks: [FarmTask] { data.tasks.filter { !$0.isCompleted }.sorted { $0.date < $1.date } }
    func machine(_ id: UUID) -> Machine? { data.machines.first { $0.id == id } }

    @discardableResult
    private func commit(_ updated: FarmData) -> Bool {
        guard storageAvailable else {
            errorMessage = "Speichern ist wegen eines Ladefehlers gesperrt. Deine vorhandene Datei bleibt erhalten."
            return false
        }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let bytes = try JSONEncoder().encode(updated)
            try bytes.write(to: fileURL, options: .atomic)
            data = updated
            return true
        } catch {
            errorMessage = "Speichern fehlgeschlagen: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func save(_ machine: Machine) -> Bool {
        var updated = data
        if let index = updated.machines.firstIndex(where: { $0.id == machine.id }) {
            updated.machines[index] = machine
        } else {
            guard updated.machines.count < Self.freeMachineLimit else {
                errorMessage = "Die kostenlose Version umfasst 20 Geräte. Bezahlpakete sind in diesem Prototyp noch nicht verfügbar."
                return false
            }
            updated.machines.append(machine)
        }
        return commit(updated)
    }

    @discardableResult
    func save(_ task: FarmTask) -> Bool {
        guard machine(task.machineID) != nil else { return false }
        var updated = data
        if let index = updated.tasks.firstIndex(where: { $0.id == task.id }) {
            updated.tasks[index] = task
        } else { updated.tasks.append(task) }
        return commit(updated)
    }

    func toggle(_ task: FarmTask) {
        var updated = task
        updated.isCompleted.toggle()
        save(updated)
    }

    func markExported(_ task: FarmTask) {
        var updated = task
        updated.calendarExportedAt = .now
        save(updated)
    }

    @discardableResult
    func renameFarm(_ name: String) -> Bool {
        var updated = data
        updated.farmName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !updated.farmName.isEmpty else { return false }
        return commit(updated)
    }
}
