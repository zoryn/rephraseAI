import SwiftUI
import UniformTypeIdentifiers

struct ModesView: View {

    @State private var settings = SettingsModel.shared
    @State private var editingMode: Mode?

    var body: some View {
        VStack(spacing: 0) {
            if settings.modes.isEmpty {
                emptyState
            } else {
                modeList
            }
            Divider()
            bottomBar
        }
        .frame(minWidth: 420)
        .sheet(item: $editingMode) { mode in
            ModeEditSheet(mode: mode) { updated in
                if let idx = settings.modes.firstIndex(where: { $0.id == updated.id }) {
                    settings.modes[idx] = updated
                }
            }
        }
        .onAppear { resizeWindowToFit() }
        .onChange(of: settings.modes.count) { resizeWindowToFit() }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("No Modes")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Click + to create a mode. When active, a mode's prompt replaces the default refinement prompt.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var modeList: some View {
        VStack(spacing: 0) {
            ForEach(settings.modes) { mode in
                ModeRow(
                    mode: mode,
                    isActive: settings.activeModeId == mode.id,
                    onSelect: { selectMode(mode) },
                    onEdit: { editingMode = mode }
                )
                Divider()
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            Button(action: addMode) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)

            Button(action: removeSelectedMode) {
                Image(systemName: "minus")
            }
            .buttonStyle(.borderless)
            .disabled(settings.activeModeId == nil || settings.modes.count <= 1)

            Divider()
                .frame(height: 16)

            Button(action: exportModes) {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.borderless)

            Button(action: importModes) {
                Image(systemName: "square.and.arrow.down")
            }
            .buttonStyle(.borderless)

            Spacer()

            if let name = settings.activeModeName {
                Text("Active: \(name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func addMode() {
        let newMode = Mode()
        settings.modes.append(newMode)
        editingMode = newMode
    }

    private func removeSelectedMode() {
        guard let activeId = settings.activeModeId else { return }
        settings.modes.removeAll { $0.id == activeId }
        settings.activeModeId = settings.modes.first?.id
    }

    private func selectMode(_ mode: Mode) {
        settings.activeModeId = mode.id
    }

    private func exportModes() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "rephraseAI-modes.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(settings.modes) else { return }
        try? data.write(to: url)
    }

    private func importModes() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let data = try? Data(contentsOf: url),
              let imported = try? JSONDecoder().decode([Mode].self, from: data),
              !imported.isEmpty else { return }
        settings.modes = imported
        settings.activeModeId = imported.first?.id
    }

    private func resizeWindowToFit() {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first(where: { $0.title == "rephraseAI Modes" }) else { return }
            let rowHeight: CGFloat = 47
            let bottomBarHeight: CGFloat = 37
            let contentHeight = CGFloat(max(settings.modes.count, 1)) * rowHeight + bottomBarHeight
            let clampedHeight = min(max(contentHeight, 80), 600)
            let titleBarHeight = window.frame.height - window.contentLayoutRect.height
            let newHeight = clampedHeight + titleBarHeight
            var frame = window.frame
            frame.origin.y += frame.height - newHeight
            frame.size.height = newHeight
            window.setFrame(frame, display: true, animate: true)
        }
    }
}

// MARK: - Mode Row

struct ModeRow: View {
    let mode: Mode
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isActive ? Color.accentColor : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(mode.title)
                            .fontWeight(isActive ? .semibold : .regular)
                        if !mode.prompt.isEmpty {
                            Text(mode.prompt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button("Edit") { onEdit() }
                .buttonStyle(.borderless)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .onTapGesture(count: 2) { onEdit() }
    }
}

// MARK: - Edit Sheet

struct ModeEditSheet: View {
    @State var mode: Mode
    @Environment(\.dismiss) private var dismiss
    let onSave: (Mode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Mode")
                .font(.headline)

            TextField("Title", text: $mode.title)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 4) {
                Text("Prompt")
                    .font(.subheadline)
                TextEditor(text: $mode.prompt)
                    .frame(minHeight: 120)
                    .font(.body)
                Text("This prompt is sent as the system instruction when this mode is active.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    onSave(mode)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(mode.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400, height: 300)
    }
}

#Preview {
    ModesView()
}
