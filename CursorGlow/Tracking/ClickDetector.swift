import AppKit

enum ClickType {
    case left
    case right
}

final class ClickDetector {
    var onClickDetected: ((ClickType) -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?

    func start() {
        let eventMask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown]

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            let type: ClickType = event.type == .leftMouseDown ? .left : .right
            self?.onClickDetected?(type)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            let type: ClickType = event.type == .leftMouseDown ? .left : .right
            self?.onClickDetected?(type)
            return event
        }
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    deinit {
        stop()
    }
}
