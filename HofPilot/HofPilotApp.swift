import SwiftUI

@main
struct HofPilotApp: App {
    @StateObject private var store = FarmStore()
    @AppStorage("hofpilot.onboardingCompleted") private var onboardingCompleted = false

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingCompleted {
                    RootView()
                        .environmentObject(store)
                } else {
                    WelcomeView {
                        onboardingCompleted = true
                    }
                }
            }
            .tint(Theme.green)
        }
    }
}

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 86))
                    .foregroundStyle(Theme.green)

                VStack(spacing: 10) {
                    Text("HofPilot")
                        .font(.largeTitle.bold())
                    Text("Dein Hof. Deine Maschinen. Deine Termine.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 18) {
                    FeatureRow(icon: "shippingbox.fill", title: "Maschinen verwalten", text: "Geräte, Status und wichtige Informationen an einem Ort.")
                    FeatureRow(icon: "checklist", title: "Aufgaben planen", text: "Wartungen und Termine übersichtlich organisieren.")
                    FeatureRow(icon: "calendar.badge.plus", title: "Kalender verbinden", text: "Termine direkt an den Apple-Kalender übergeben.")
                    FeatureRow(icon: "qrcode.viewfinder", title: "QR-Codes nutzen", text: "Maschinen schnell scannen und direkt öffnen.")
                }
                .padding(.horizontal)

                Spacer()

                Button(action: onContinue) {
                    Text("HofPilot starten")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("Der aktuelle Prototyp speichert deine Hofdaten lokal auf diesem Gerät. Benutzerkonten und gemeinsame Hof-Synchronisierung folgen als nächster Entwicklungsschritt.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Theme.green)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

enum Theme {
    static let green = Color("AccentColor")
    static let yellow = Color(red: 0.95, green: 0.79, blue: 0.30)
}

struct MachinePhoto: View {
    let machine: Machine
    var body: some View {
        Group {
            if let data = machine.photo, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFit()
            } else {
                ZStack {
                    LinearGradient(colors: [Theme.green.opacity(0.18), Theme.yellow.opacity(0.18)], startPoint: .bottomLeading, endPoint: .topTrailing)
                    Image(systemName: machine.symbol).font(.system(size: 48)).foregroundStyle(Theme.green)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityLabel("Foto von \(machine.name)")
    }
}

struct StatusLabel: View {
    let status: MachineStatus
    var color: Color {
        switch status { case .ready: return Theme.green; case .limited: return .orange; case .blocked: return .red }
    }
    var body: some View { Label(status.rawValue, systemImage: status.symbol).foregroundStyle(color) }
}
