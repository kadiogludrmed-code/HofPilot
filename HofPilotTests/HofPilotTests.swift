import XCTest
@testable import HofPilot

final class HofPilotTests: XCTestCase {
    func testMachineLinksRejectForeignURLs() {
        let id = UUID()
        XCTAssertEqual(MachineLink.id(from: "hofpilot://machine/\(id)"), id)
        XCTAssertEqual(MachineLink.id(from: id.uuidString), id)
        XCTAssertNil(MachineLink.id(from: "https://example.com/\(id)"))
        XCTAssertNil(MachineLink.id(from: "hofpilot://other/\(id)"))
        XCTAssertNil(MachineLink.id(from: "hofpilot://machine/extra/\(id)"))
    }

    @MainActor
    func testPersistenceAndCompletionSurviveRestart() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.json")
        let store = FarmStore(fileURL: url)
        var machine = Machine(name: "Traktor 01")
        machine.photo = Data([1, 2, 3])
        XCTAssertTrue(store.save(machine))
        let task = FarmTask(machineID: machine.id, title: "Prüfung", date: .now)
        XCTAssertTrue(store.save(task))
        store.toggle(task)
        XCTAssertTrue(store.renameFarm("Testhof"))
        let restored = FarmStore(fileURL: url)
        XCTAssertEqual(restored.data.farmName, "Testhof")
        XCTAssertEqual(restored.machine(machine.id)?.photo, machine.photo)
        XCTAssertTrue(try XCTUnwrap(restored.data.tasks.first).isCompleted)
        XCTAssertTrue(restored.pendingTasks.isEmpty)
    }

    @MainActor
    func testFreeLimitAllowsEditingButNotTwentyFirstMachine() {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FarmStore(fileURL: directory.appendingPathComponent("test.json"))
        for index in 1...20 { XCTAssertTrue(store.save(Machine(name: "Gerät \(index)"))) }
        XCTAssertFalse(store.save(Machine(name: "Gerät 21")))
        var existing = store.data.machines[0]
        existing.name = "Umbenannt"
        XCTAssertTrue(store.save(existing))
        XCTAssertEqual(store.data.machines.count, 20)
        XCTAssertEqual(store.machine(existing.id)?.name, "Umbenannt")
    }

    @MainActor
    func testCorruptFileIsNeverOverwritten() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.json")
        let original = Data("invalid".utf8)
        try original.write(to: url)
        let store = FarmStore(fileURL: url)
        XCTAssertFalse(store.storageAvailable)
        XCTAssertFalse(store.save(Machine(name: "Neu")))
        XCTAssertEqual(try Data(contentsOf: url), original)
    }

    @MainActor
    func testOrphanTaskIsRejected() {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FarmStore(fileURL: directory.appendingPathComponent("test.json"))
        XCTAssertFalse(store.save(FarmTask(machineID: UUID(), title: "Ohne Gerät", date: .now)))
        XCTAssertTrue(store.data.tasks.isEmpty)
    }
}
