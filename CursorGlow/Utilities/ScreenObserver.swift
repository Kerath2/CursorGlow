import AppKit

final class ScreenObserver {
    var onScreensChanged: (() -> Void)?

    func start() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func stop() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func screensDidChange(_ notification: Notification) {
        onScreensChanged?()
    }

    deinit {
        stop()
    }
}
