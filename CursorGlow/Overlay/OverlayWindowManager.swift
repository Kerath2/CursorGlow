import AppKit
import Combine

final class OverlayWindowManager {
    private var windows: [OverlayWindow] = []
    private var activeWindow: OverlayWindow?
    private var cancellables = Set<AnyCancellable>()
    private let settings = CursorSettings.shared
    /// Color override from cursor-type detection (nil = use default highlightColor)
    private var cursorTypeColor: NSColor?

    init() {
        observeSettings()
    }

    func createWindows() {
        closeAll()
        for screen in NSScreen.screens {
            let window = OverlayWindow(screen: screen)
            windows.append(window)
        }
        updateVisibility()
    }

    func closeAll() {
        for window in windows {
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()
        activeWindow = nil
    }

    func recreateWindows() {
        createWindows()
    }

    func updateVisibility() {
        if settings.isActive {
            for window in windows {
                window.orderFrontRegardless()
            }
        } else {
            for window in windows {
                window.orderOut(nil)
            }
        }
    }

    func updateCursorPosition(_ screenPoint: NSPoint) {
        guard settings.isActive else { return }

        // Find the screen containing the cursor
        var targetWindow: OverlayWindow?
        for window in windows {
            if let screen = window.screen, NSMouseInRect(screenPoint, screen.frame, false) {
                targetWindow = window
                break
            }
        }

        // Show highlight only on the active screen
        if let target = targetWindow {
            if activeWindow !== target {
                activeWindow?.overlayView?.highlightLayer.opacity = 0
                activeWindow?.overlayView?.clickAnimationLayer.opacity = 0
                activeWindow = target
                target.overlayView?.highlightLayer.opacity = 1
                target.overlayView?.clickAnimationLayer.opacity = 1
            }

            // Convert screen coordinates to window-local, offset to center on cursor body
            let offsetPoint = NSPoint(
                x: screenPoint.x + settings.cursorOffsetX,
                y: screenPoint.y + settings.cursorOffsetY
            )
            let localPoint = target.convertPoint(fromScreen: offsetPoint)
            target.overlayView?.updateHighlightPosition(localPoint)
        }
    }

    /// Set cursor-type color override. Pass nil to reset to default highlightColor.
    func setCursorTypeColor(_ color: NSColor?) {
        cursorTypeColor = color
        let effectiveColor = color ?? settings.highlightColor
        for window in windows {
            window.overlayView?.updateHighlightColor(effectiveColor)
        }
    }

    func triggerClickAnimation(clickType: ClickType) {
        guard settings.isActive, settings.clickAnimationEnabled else { return }
        let color: NSColor = clickType == .left ? settings.leftClickColor : settings.rightClickColor
        let tilt: CursorHighlightLayer.TiltDirection
        if settings.tiltOnClickEnabled {
            tilt = clickType == .left ? .left : .right
        } else {
            tilt = .none
        }
        activeWindow?.overlayView?.triggerClickAnimation(color: color, tiltDirection: tilt)
    }

    func setHighlightVisible(_ visible: Bool, animated: Bool = true) {
        let targetOpacity: Float = visible ? 1.0 : 0.0
        let duration = visible ? 0.2 : 0.5

        for window in windows {
            guard let overlayView = window.overlayView else { continue }
            if animated {
                CATransaction.begin()
                CATransaction.setAnimationDuration(duration)
                overlayView.highlightLayer.opacity = targetOpacity
                CATransaction.commit()
            } else {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                overlayView.highlightLayer.opacity = targetOpacity
                CATransaction.commit()
            }
        }
    }

    func updateAppearance() {
        for window in windows {
            window.overlayView?.updateHighlightAppearance(settings: settings)
        }
        // Re-apply cursor-type color override (updateHighlightAppearance resets to highlightColor)
        if let overrideColor = cursorTypeColor {
            for window in windows {
                window.overlayView?.updateHighlightColor(overrideColor)
            }
        }
    }

    private func observeSettings() {
        settings.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateAppearance()
                self?.updateVisibility()
            }
        }.store(in: &cancellables)
    }
}
