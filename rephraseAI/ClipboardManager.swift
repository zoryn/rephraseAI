import AppKit
import CoreGraphics

enum ClipboardManager {

    // Snapshot of all pasteboard items so we can restore after pasting
    struct Snapshot {
        let items: [NSPasteboardItem]
    }

    // Save all current pasteboard contents
    static func save() -> Snapshot {
        let pb = NSPasteboard.general
        let items = pb.pasteboardItems?.map { originalItem -> NSPasteboardItem in
            let copy = NSPasteboardItem()
            for type in originalItem.types {
                if let data = originalItem.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        } ?? []
        return Snapshot(items: items)
    }

    // Restore pasteboard to a previously saved snapshot
    static func restore(_ snapshot: Snapshot) {
        let pb = NSPasteboard.general
        pb.clearContents()
        if !snapshot.items.isEmpty {
            pb.writeObjects(snapshot.items)
        }
    }

    // Read plain text from clipboard
    static func readText() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    // Write plain text to clipboard
    static func writeText(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    // Simulate Cmd+C (keyCode 8 = 'c')
    static func simulateCopy() {
        postKeyEvent(virtualKey: 8, flags: .maskCommand)
    }

    // Simulate Cmd+V (keyCode 9 = 'v')
    static func simulatePaste() {
        postKeyEvent(virtualKey: 9, flags: .maskCommand)
    }

    private static func postKeyEvent(virtualKey: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true),
              let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false)
        else { return }
        keyDown.flags = flags
        keyUp.flags   = flags
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
