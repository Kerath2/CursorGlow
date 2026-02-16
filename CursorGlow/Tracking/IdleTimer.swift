import Foundation

final class IdleTimer {
    var onIdle: (() -> Void)?
    var onResume: (() -> Void)?

    private var timer: Timer?
    private var isIdle = false
    private let settings = CursorSettings.shared

    func resetTimer() {
        timer?.invalidate()

        if isIdle {
            isIdle = false
            onResume?()
        }

        guard settings.autoHideEnabled else { return }

        timer = Timer.scheduledTimer(withTimeInterval: settings.autoHideDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.isIdle = true
            self.onIdle?()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isIdle = false
    }

    deinit {
        stop()
    }
}
