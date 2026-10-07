import SwiftUI
import EventKit
import EventKitUI

/// iOS 17's system editor saves on the user's behalf without full calendar access.
struct CalendarEditor: UIViewControllerRepresentable {
    let task: FarmTask
    let machine: Machine
    let onFinish: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }
    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.title = "\(task.title) · \(machine.name)"
        event.startDate = task.date
        event.endDate = task.date.addingTimeInterval(3600)
        event.location = machine.location
        event.notes = task.notes + "\n\nAus HofPilot übernommen. Änderungen werden nicht synchronisiert."
        event.url = URL(string: machine.qrPayload)
        event.addAlarm(EKAlarm(relativeOffset: -3600))
        controller.eventStore = store
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ controller: EKEventEditViewController, context: Context) { }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let onFinish: (Bool) -> Void
        init(onFinish: @escaping (Bool) -> Void) { self.onFinish = onFinish }
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            onFinish(action == .saved)
        }
    }
}
