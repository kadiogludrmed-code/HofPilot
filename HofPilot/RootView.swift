import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: FarmStore
    @State private var linkedMachine: Machine?
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }.tabItem { Label("Hof", systemImage: "house.fill") }
            NavigationStack { MachineListView() }.tabItem { Label("Maschinen", systemImage: "shippingbox.fill") }
            NavigationStack { ScanView() }.tabItem { Label("Scannen", systemImage: "qrcode.viewfinder") }
            NavigationStack { TaskListView() }.tabItem { Label("Aufgaben", systemImage: "checklist") }
        }
        .onOpenURL { url in
            if let id = MachineLink.id(from: url.absoluteString), let machine = store.machine(id) {
                linkedMachine = machine
            } else { store.errorMessage = "Dieses Gerät ist auf diesem iPhone nicht gespeichert. Gemeinsame Hofdaten folgen in einer späteren Version." }
        }
        .sheet(item: $linkedMachine) { machine in
            NavigationStack {
                MachineDetailView(machineID: machine.id)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Schließen") { linkedMachine = nil } } }
            }
        }
        .alert("Hinweis", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK") { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: FarmStore
    @State private var addMachine = false
    @State private var settings = false
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label("HofPilot", systemImage: "leaf.fill").font(.title.bold()).foregroundStyle(Theme.green)
                    Text("Maschinen. Termine. Alles im Blick.").font(.subheadline)
                    HStack(spacing: 24) {
                        Label("\(store.data.machines.count) Geräte", systemImage: "shippingbox")
                        Label("\(store.pendingTasks.count) offen", systemImage: "checklist")
                    }.font(.headline)
                }.padding(.vertical, 12)
            }
            Section("Als Nächstes") {
                if store.pendingTasks.isEmpty {
                    Text("Keine offenen Aufgaben. Lege ein Gerät und dessen ersten Termin an.").foregroundStyle(.secondary)
                }
                ForEach(Array(store.pendingTasks.prefix(5))) { task in
                    NavigationLink { TaskDetailView(taskID: task.id) } label: { TaskRow(task: task) }
                }
            }
            Section {
                Button { addMachine = true } label: { Label("Gerät hinzufügen", systemImage: "plus.circle.fill") }
                Text("\(store.data.machines.count) von 20 kostenlosen Geräten").font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                Label("Lokaler Prototyp", systemImage: "iphone")
                Text("Deine Einträge bleiben auf diesem Gerät. Anmeldung, Hofteam, KI und Web-Synchronisierung sind noch nicht verbunden.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle(store.data.farmName)
        .toolbar { Button { settings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel("Hof-Einstellungen") }
        .sheet(isPresented: $addMachine) { MachineEditor(machine: Machine(name: "")) }
        .sheet(isPresented: $settings) { FarmSettingsView(name: store.data.farmName) }
    }
}

struct FarmSettingsView: View {
    @EnvironmentObject private var store: FarmStore
    @Environment(\.dismiss) private var dismiss
    @State var name: String
    var body: some View {
        NavigationStack {
            Form {
                Section("Dein Hof") { TextField("Hofname", text: $name) }
                Section("Entwicklungsstand") {
                    Text("Version 0.1 · iOS 17+")
                    Text("Kein Benutzerkonto erforderlich. Apple-, Google- und E-Mail-Anmeldung folgen mit dem gemeinsamen Serverdienst.")
                    Text("Termine werden in der App angezeigt. Automatische Benachrichtigungen sind noch nicht implementiert. Du kannst Termine mit Erinnerungen in deinen Kalender übernehmen.")
                }
            }.navigationTitle("Einstellungen")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") { if store.renameFarm(name) { dismiss() } }
                            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
    }
}
