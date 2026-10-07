import SwiftUI

@main
struct HofPilotApp: App {
    @StateObject private var store = FarmStore()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(Theme.green)
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
