import SwiftUI
import PhotosUI

struct MachineListView: View {
    @EnvironmentObject private var store: FarmStore
    @State private var search = ""
    @State private var adding = false
    var machines: [Machine] {
        store.data.machines.filter { search.isEmpty || "\($0.name) \($0.manufacturer) \($0.model) \($0.serialNumber)".localizedCaseInsensitiveContains(search) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    var body: some View {
        List {
            ForEach(machines) { machine in
                NavigationLink { MachineDetailView(machineID: machine.id) } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(machine.name).font(.headline)
                        Text([machine.category, machine.manufacturer, machine.model].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.subheadline).foregroundStyle(.secondary)
                        StatusLabel(status: machine.status).font(.caption)
                    }.padding(.vertical, 4)
                }
            }
        }
        .overlay {
            if machines.isEmpty {
                ContentUnavailableView(search.isEmpty ? "Deine erste Maschine" : "Keine Treffer", systemImage: "shippingbox", description: Text(search.isEmpty ? "Tippe auf +, um ein Gerät anzulegen." : "Versuche einen anderen Suchbegriff."))
            }
        }
        .searchable(text: $search, prompt: "Name, Marke oder Seriennummer")
        .navigationTitle("Maschinen")
        .toolbar { Button { adding = true } label: { Image(systemName: "plus") }.accessibilityLabel("Gerät hinzufügen") }
        .sheet(isPresented: $adding) { MachineEditor(machine: Machine(name: "")) }
    }
}

struct MachineDetailView: View {
    @EnvironmentObject private var store: FarmStore
    let machineID: UUID
    @State private var editing = false
    @State private var addingTask = false
    @State private var showingQR = false
    var body: some View {
        Group {
            if let machine = store.machine(machineID) {
                List {
                    Section { MachinePhoto(machine: machine).listRowInsets(EdgeInsets()) }
                    Section { StatusLabel(status: machine.status) }
                    Section("Gerätedaten") {
                        LabeledContent("Kategorie", value: machine.category)
                        LabeledContent("Hersteller", value: machine.manufacturer.isEmpty ? "–" : machine.manufacturer)
                        LabeledContent("Modell", value: machine.model.isEmpty ? "–" : machine.model)
                        LabeledContent("Seriennummer / Kennzeichen", value: machine.serialNumber.isEmpty ? "–" : machine.serialNumber)
                        LabeledContent("Standort", value: machine.location.isEmpty ? "–" : machine.location)
                    }
                    Section("Aufgaben und Verlauf") {
                        Button { addingTask = true } label: { Label("Termin oder Mangel eintragen", systemImage: "plus.circle") }
                        ForEach(store.data.tasks.filter { $0.machineID == machineID }.sorted { $0.date < $1.date }) { task in
                            NavigationLink { TaskDetailView(taskID: task.id) } label: { TaskRow(task: task) }
                        }
                    }
                    if !machine.notes.isEmpty { Section("Notizen") { Text(machine.notes) } }
                    Section { Button { showingQR = true } label: { Label("QR-Etikett anzeigen", systemImage: "qrcode") } }
                }
                .navigationTitle(machine.name)
                .toolbar { Button("Bearbeiten") { editing = true } }
                .sheet(isPresented: $editing) { MachineEditor(machine: machine) }
                .sheet(isPresented: $addingTask) { TaskEditor(machineID: machineID) }
                .sheet(isPresented: $showingQR) { QRLabelView(machine: machine) }
            } else { ContentUnavailableView("Gerät nicht gefunden", systemImage: "questionmark.folder") }
        }
    }
}

struct MachineEditor: View {
    @EnvironmentObject private var store: FarmStore
    @Environment(\.dismiss) private var dismiss
    @State var machine: Machine
    @State private var photoItem: PhotosPickerItem?
    @State private var photoError: String?
    @State private var loadingPhoto = false
    @State private var saveError: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Foto") {
                    MachinePhoto(machine: machine)
                    PhotosPicker(selection: $photoItem, matching: .images) { Label("Foto auswählen", systemImage: "photo") }
                    if loadingPhoto { ProgressView("Foto wird geladen …") }
                    if machine.photo != nil { Button("Foto entfernen", role: .destructive) { machine.photo = nil; photoItem = nil } }
                    if let photoError { Text(photoError).foregroundStyle(.red) }
                }
                Section("Maschine") {
                    TextField("Name, z. B. Traktor 01", text: $machine.name)
                    Picker("Kategorie", selection: $machine.category) { ForEach(Machine.categories, id: \.self) { Text($0) } }
                    TextField("Hersteller", text: $machine.manufacturer)
                    TextField("Modell", text: $machine.model)
                    TextField("Seriennummer / Kennzeichen", text: $machine.serialNumber).textInputAutocapitalization(.characters)
                    TextField("Standort", text: $machine.location)
                    Picker("Status", selection: $machine.status) { ForEach(MachineStatus.allCases) { Text($0.rawValue).tag($0) } }
                }
                Section("Notizen") { TextEditor(text: $machine.notes).frame(minHeight: 80) }
                if let saveError { Section { Text(saveError).foregroundStyle(.red) } }
            }
            .navigationTitle("Geräteakte")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        machine.name = machine.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if store.save(machine) { dismiss() } else { saveError = store.errorMessage }
                    }.disabled(machine.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || loadingPhoto)
                }
            }
            .task(id: photoItem) {
                guard let item = photoItem else { return }
                loadingPhoto = true
                defer { loadingPhoto = false }
                do {
                    guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                        photoError = "Das Foto konnte nicht gelesen werden."; return
                    }
                    try Task.checkCancellation()
                    let scale = min(1, 1200 / max(image.size.width, image.size.height))
                    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                    let format = UIGraphicsImageRendererFormat()
                    format.scale = 1
                    let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
                    machine.photo = resized.jpegData(compressionQuality: 0.75)
                    photoError = nil
                } catch is CancellationError { }
                catch { photoError = "Foto konnte nicht geladen werden: \(error.localizedDescription)" }
            }
        }
    }
}
