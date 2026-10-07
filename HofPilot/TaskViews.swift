import SwiftUI

struct TaskRow: View {
    @EnvironmentObject private var store: FarmStore
    let task: FarmTask
    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "calendar")
                .foregroundStyle(task.isCompleted ? Theme.green : .secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title).font(.headline)
                Text(store.machine(task.machineID)?.name ?? "Gerät").font(.caption).foregroundStyle(.secondary)
                Text(task.date, format: .dateTime.day().month().year().hour().minute()).font(.subheadline)
                if task.isCompleted { Text("Erledigt").font(.caption).foregroundStyle(Theme.green) }
                else if task.date < .now { Text("Überfällig").font(.caption).foregroundStyle(.red) }
            }
        }.padding(.vertical, 4)
    }
}

struct TaskListView: View {
    @EnvironmentObject private var store: FarmStore
    @State private var includeCompleted = false
    var tasks: [FarmTask] {
        store.data.tasks.filter { includeCompleted || !$0.isCompleted }.sorted { $0.date < $1.date }
    }
    var body: some View {
        List {
            Toggle("Erledigte anzeigen", isOn: $includeCompleted)
            if tasks.isEmpty { Text("Keine Aufgaben. Öffne eine Geräteakte, um einen Termin oder Mangel einzutragen.").foregroundStyle(.secondary) }
            ForEach(tasks) { task in
                NavigationLink { TaskDetailView(taskID: task.id) } label: { TaskRow(task: task) }
            }
        }.navigationTitle("Aufgaben")
    }
}

struct TaskEditor: View {
    @EnvironmentObject private var store: FarmStore
    @Environment(\.dismiss) private var dismiss
    let machineID: UUID
    @State private var title = ""
    @State private var date = Date.now
    @State private var notes = ""
    @State private var saveError: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Termin oder Mangel") {
                    TextField("Titel, z. B. Ölwechsel", text: $title)
                    DatePicker("Fällig am", selection: $date)
                    TextField("Notizen", text: $notes, axis: .vertical).lineLimit(3...8)
                }
                Section { Text("Bei einem sicherheitsrelevanten Mangel kannst du das Gerät in seiner Geräteakte auf ‚Gesperrt‘ setzen. Diese Aufgabe ändert den Gerätestatus nicht automatisch.").font(.footnote) }
                if let saveError { Text(saveError).foregroundStyle(.red) }
            }
            .navigationTitle("Neue Aufgabe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let task = FarmTask(machineID: machineID, title: title.trimmingCharacters(in: .whitespacesAndNewlines), date: date, notes: notes)
                        if store.save(task) { dismiss() } else { saveError = store.errorMessage ?? "Das Gerät ist nicht mehr vorhanden." }
                    }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct TaskDetailView: View {
    @EnvironmentObject private var store: FarmStore
    let taskID: UUID
    @State private var showCalendar = false
    @State private var confirmDuplicate = false
    var body: some View {
        if let task = store.data.tasks.first(where: { $0.id == taskID }), let machine = store.machine(task.machineID) {
            List {
                Section {
                    Text(task.title).font(.title2.bold())
                    Text(machine.name).foregroundStyle(.secondary)
                    Text(task.date, format: .dateTime.day().month().year().hour().minute())
                    if !task.notes.isEmpty { Text(task.notes) }
                }
                Section {
                    Button { store.toggle(task) } label: {
                        Label(task.isCompleted ? "Wieder öffnen" : "Als erledigt markieren", systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle")
                    }
                    Button {
                        if task.calendarExportedAt != nil { confirmDuplicate = true } else { showCalendar = true }
                    } label: { Label("Zum Kalender hinzufügen", systemImage: "calendar.badge.plus") }
                    if let exportedAt = task.calendarExportedAt {
                        Text("Zuletzt übertragen: \(exportedAt.formatted(date: .abbreviated, time: .shortened))").font(.caption)
                    }
                } footer: {
                    Text("Einmalige Übernahme, keine Synchronisierung. Änderungen und das Erledigen in HofPilot ändern den Kalendereintrag nicht. Google-Kalender sind hier auswählbar, wenn sie in iOS als beschreibbare Kalender eingerichtet sind.")
                }
            }
            .navigationTitle("Aufgabe")
            .sheet(isPresented: $showCalendar) {
                CalendarEditor(task: task, machine: machine) { saved in
                    if saved { store.markExported(task) }
                    showCalendar = false
                }
            }
            .confirmationDialog("Dieser Termin wurde bereits übertragen. Erneutes Hinzufügen kann ein Duplikat erzeugen.", isPresented: $confirmDuplicate, titleVisibility: .visible) {
                Button("Trotzdem hinzufügen") { showCalendar = true }
                Button("Abbrechen", role: .cancel) { }
            }
        } else { ContentUnavailableView("Aufgabe nicht gefunden", systemImage: "calendar") }
    }
}
