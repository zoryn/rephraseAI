import Foundation
import AppKit

@MainActor
class TextProcessor {

    weak var delegate: AppDelegate?

    // Called when the hotkey fires
    func processSelectedText() {
        Task {
            // 1. Check Accessibility permission first
            guard AXIsProcessTrusted() else {
                delegate?.showAccessibilityAlert()
                return
            }

            // 2. Save current clipboard so we can restore it later
            let saved = ClipboardManager.save()

            // 3. Simulate Cmd+C to copy whatever is selected
            ClipboardManager.simulateCopy()

            // 4. Wait briefly for the copy event to be processed by the target app
            try await Task.sleep(nanoseconds: 150_000_000) // 150 ms

            // 5. Read the copied text
            guard let text = ClipboardManager.readText(), !text.isEmpty else {
                ClipboardManager.restore(saved)
                return
            }

            // 6. Show processing state in menu bar
            delegate?.setProcessing(true)

            do {
                // 7. Send to LLM
                let service = LLMServiceFactory.make()
                let refined = try await service.refine(text)

                // 8. Write refined text to clipboard and paste it
                ClipboardManager.writeText(refined)
                ClipboardManager.simulatePaste()

                // 9. Wait for paste to complete before restoring clipboard
                try await Task.sleep(nanoseconds: 500_000_000) // 500 ms
                ClipboardManager.restore(saved)

            } catch {
                // On failure: restore clipboard and show error
                ClipboardManager.restore(saved)
                delegate?.showError(error)
            }

            delegate?.setProcessing(false)
        }
    }
}
