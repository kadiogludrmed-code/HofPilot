import SwiftUI
import CoreImage.CIFilterBuiltins
import VisionKit
import AVFoundation

enum QRCode {
    static func image(for payload: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cgImage = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct QRLabelView: View {
    @Environment(\.dismiss) private var dismiss
    let machine: Machine
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("HofPilot").font(.title.bold()).foregroundStyle(Theme.green)
                    if let image = QRCode.image(for: machine.qrPayload) {
                        Image(uiImage: image).interpolation(.none).resizable().scaledToFit()
                            .frame(width: 230, height: 230).padding(24).background(.white)
                            .accessibilityLabel("QR-Code für \(machine.name)")
                        ShareLink(item: Image(uiImage: image), preview: SharePreview(machine.name, image: Image(uiImage: image))) {
                            Label("QR-Bild teilen", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            let printer = UIPrintInteractionController.shared
                            let info = UIPrintInfo(dictionary: nil)
                            info.jobName = "HofPilot · \(machine.name)"
                            printer.printInfo = info
                            printer.printingItem = labelImage(qr: image)
                            printer.present(animated: true, completionHandler: nil)
                        } label: { Label("Etikett drucken", systemImage: "printer") }
                    }
                    Text(machine.name).font(.title2.bold())
                    Text(machine.id.uuidString).font(.caption.monospaced()).textSelection(.enabled)
                    Text("Dieser Code öffnet die lokale Geräteakte. Andere Mitarbeitende können erst nach Einführung der Hof-Synchronisierung auf dieselben Daten zugreifen.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding()
            }.navigationTitle("QR-Etikett")
                .toolbar { Button("Fertig") { dismiss() } }
        }
    }

    private func labelImage(qr: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 600, height: 760), format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 600, height: 760))
            context.cgContext.interpolationQuality = .none
            qr.draw(in: CGRect(x: 80, y: 90, width: 440, height: 440))
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let heading: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 30), .foregroundColor: UIColor.black, .paragraphStyle: paragraph]
            ("HofPilot" as NSString).draw(in: CGRect(x: 20, y: 25, width: 560, height: 45), withAttributes: heading)
            (machine.name as NSString).draw(in: CGRect(x: 20, y: 570, width: 560, height: 100), withAttributes: heading)
            let small: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: UIColor.black, .paragraphStyle: paragraph]
            (machine.id.uuidString as NSString).draw(in: CGRect(x: 10, y: 690, width: 580, height: 40), withAttributes: small)
        }
    }
}

struct ScanView: View {
    @EnvironmentObject private var store: FarmStore
    @State private var input = ""
    @State private var scanning = false
    @State private var found: Machine?
    @State private var message: String?
    var body: some View {
        Form {
            Section {
                Label("Direkt zur Geräteakte", systemImage: "qrcode.viewfinder").font(.headline)
                Text("Scanne ein HofPilot-Etikett. Im Simulator kannst du stattdessen die Geräte-ID aus dem Etikett einfügen.")
                Button("Kamera öffnen") {
                    Task {
                        let allowed = await AVCaptureDevice.requestAccess(for: .video)
                        guard allowed else { message = "Bitte erlaube den Kamerazugriff in den iOS-Einstellungen für HofPilot."; return }
                        guard DataScannerViewController.isSupported && DataScannerViewController.isAvailable else {
                            message = "Der Scanner ist auf diesem Gerät nicht verfügbar. Nutze die Geräte-ID unten."; return
                        }
                        scanning = true
                    }
                }
            }
            Section("Geräte-ID oder HofPilot-Link") {
                TextField("ID einfügen", text: $input).textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Gerät öffnen") { resolve(input) }.disabled(input.isEmpty)
            }
            if let message { Section { Text(message).foregroundStyle(.secondary) } }
        }
        .navigationTitle("Scannen")
        .sheet(isPresented: $scanning, onDismiss: {
            if !input.isEmpty { resolve(input) }
        }) {
            NavigationStack {
                QRScanner { result in
                    input = result
                    scanning = false
                } onError: { error in
                    message = error
                    input = ""
                    scanning = false
                }
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("QR-Code scannen")
                .toolbar { Button("Abbrechen") { input = ""; scanning = false } }
            }
        }
        .navigationDestination(item: $found) { machine in MachineDetailView(machineID: machine.id) }
    }
    private func resolve(_ payload: String) {
        guard let id = MachineLink.id(from: payload) else { message = "Kein gültiger HofPilot-Code."; return }
        guard let machine = store.machine(id) else { message = "Dieses Gerät ist auf diesem iPhone nicht gespeichert."; return }
        message = nil
        found = machine
    }
}

struct QRScanner: UIViewControllerRepresentable {
    let onCode: (String) -> Void
    let onError: (String) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(recognizedDataTypes: [.barcode(symbologies: [.qr])], qualityLevel: .balanced, recognizesMultipleItems: false, isGuidanceEnabled: true, isHighlightingEnabled: true)
        scanner.delegate = context.coordinator
        do { try scanner.startScanning() }
        catch { DispatchQueue.main.async { onError("Scanner konnte nicht gestartet werden: \(error.localizedDescription)") } }
        return scanner
    }
    func updateUIViewController(_ controller: DataScannerViewController, context: Context) { }
    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: Coordinator) { controller.stopScanning() }
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCode: (String) -> Void
        var delivered = false
        init(onCode: @escaping (String) -> Void) { self.onCode = onCode }
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                if case .barcode(let barcode) = item, let value = barcode.payloadStringValue, !delivered {
                    delivered = true
                    dataScanner.stopScanning()
                    onCode(value)
                    return
                }
            }
        }
    }
}
