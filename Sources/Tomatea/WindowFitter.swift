import AppKit
import SwiftUI

/// MenuBarExtra windows grow to fit larger content but never shrink back,
/// so resize the window to its content, keeping it pinned under the menu bar.
struct WindowFitter: NSViewRepresentable {
    let contentID: AnyHashable

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = view.window, let contentView = window.contentView else { return }
            let contentSize = contentView.fittingSize
            guard contentSize != contentView.frame.size else { return }

            var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize))
            frame.origin.x = window.frame.minX
            frame.origin.y = window.frame.maxY - frame.height
            window.setFrame(frame, display: true)
        }
    }
}
