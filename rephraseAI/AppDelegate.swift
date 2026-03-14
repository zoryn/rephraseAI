import AppKit
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var hotkeyManager = HotkeyManager()
    private var textProcessor: TextProcessor!
    private var processingTimer: Timer?
    private var settingsWindow: NSWindow?
    private var modesWindow: NSWindow?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupTextProcessor()
        checkAccessibilityPermission()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregister()
    }

    // MARK: - Status Bar Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon(symbol: "wand.and.stars")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Modes...", action: #selector(openModes), keyEquivalent: "m"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit rephraseAI", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func setupTextProcessor() {
        textProcessor = TextProcessor()
        textProcessor.delegate = self

        hotkeyManager.onHotKeyPressed = { [weak self] in
            Task { @MainActor in
                self?.textProcessor.processSelectedText()
            }
        }
        hotkeyManager.register()
    }

    // MARK: - Icon States

    func setProcessing(_ processing: Bool) {
        processingTimer?.invalidate()
        processingTimer = nil
        if processing {
            var frame = 0
            let symbols = ["arrow.triangle.2.circlepath", "arrow.2.circlepath"]
            processingTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
                self?.updateIcon(symbol: symbols[frame % symbols.count])
                frame += 1
            }
        } else {
            updateIcon(symbol: "wand.and.stars")
        }
    }

    func showError(_ error: Error) {
        processingTimer?.invalidate()
        processingTimer = nil
        updateIcon(symbol: "exclamationmark.circle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.updateIcon(symbol: "wand.and.stars")
        }
        let content = UNMutableNotificationContent()
        content.title = "rephraseAI Error"
        content.body = error.localizedDescription
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Accessibility

    func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "rephraseAI needs Accessibility access to capture and replace selected text. Please grant access in System Settings → Privacy & Security → Accessibility."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            )
        }
    }

    private func checkAccessibilityPermission() {
        if !AXIsProcessTrusted() {
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
            AXIsProcessTrustedWithOptions(options)
        }
    }

    // MARK: - Settings Window

    @objc private func openSettings() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
        } else {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 400),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "rephraseAI Settings"
            window.contentView = NSHostingView(rootView: SettingsView())
            window.center()
            window.makeKeyAndOrderFront(nil)
            self.settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Modes Window

    @objc private func openModes() {
        if let modesWindow {
            modesWindow.makeKeyAndOrderFront(nil)
        } else {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 340),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "rephraseAI Modes"
            window.contentView = NSHostingView(rootView: ModesView())
            window.center()
            window.makeKeyAndOrderFront(nil)
            self.modesWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Helpers

    private func updateIcon(symbol: String) {
        guard let button = statusItem.button else { return }
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "rephraseAI")?
            .withSymbolConfiguration(config)
    }
}
