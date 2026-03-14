import SwiftUI

struct SettingsView: View {

    @State private var settings = SettingsModel.shared

    var body: some View {
        TabView {
            GeneralTab(settings: $settings)
                .tabItem { Label("General", systemImage: "gear") }

            AnthropicTab(settings: $settings)
                .tabItem { Label("Anthropic", systemImage: "brain") }

            OpenAITab(settings: $settings)
                .tabItem { Label("OpenAI", systemImage: "sparkles") }

            BedrockTab(settings: $settings)
                .tabItem { Label("Bedrock", systemImage: "cloud") }
        }
        .frame(width: 500, height: 380)
        .padding()
    }
}

// MARK: - General

struct GeneralTab: View {
    @Binding var settings: SettingsModel

    var body: some View {
        Form {
            Section("LLM Provider") {
                Picker("Active Provider", selection: $settings.provider) {
                    ForEach(SettingsModel.Provider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
            }

            Section("Hotkey") {
                LabeledContent("Trigger shortcut") {
                    Text("⌘ ⇧ Space")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Anthropic

struct AnthropicTab: View {
    @Binding var settings: SettingsModel
    @State private var apiKey: String = ""

    var body: some View {
        Form {
            Section("API Key") {
                SecureField("sk-ant-...", text: $apiKey)
                    .onSubmit { settings.anthropicApiKey = apiKey }
            }

            Section {
                HStack {
                    Spacer()
                    Button("Save") { settings.anthropicApiKey = apiKey }
                        .keyboardShortcut(.defaultAction)
                }
            }

            Section {
                Text("Get your API key at console.anthropic.com")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Key is stored in your Mac Keychain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear { apiKey = settings.anthropicApiKey }
    }
}

// MARK: - OpenAI

struct OpenAITab: View {
    @Binding var settings: SettingsModel
    @State private var apiKey: String = ""

    var body: some View {
        Form {
            Section("API Key") {
                SecureField("sk-...", text: $apiKey)
                    .onSubmit { settings.openaiApiKey = apiKey }
            }

            Section {
                HStack {
                    Spacer()
                    Button("Save") { settings.openaiApiKey = apiKey }
                        .keyboardShortcut(.defaultAction)
                }
            }

            Section {
                Text("Get your API key at platform.openai.com/api-keys")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Key is stored in your Mac Keychain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear { apiKey = settings.openaiApiKey }
    }
}

// MARK: - Bedrock

struct BedrockTab: View {
    @Binding var settings: SettingsModel

    var body: some View {
        Form {
            Section("AWS Profile") {
                LabeledContent("Profile Name") {
                    TextField("default", text: $settings.awsProfile)
                }
                Text("Reads credentials from ~/.aws/credentials and region from ~/.aws/config")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Model") {
                LabeledContent("Model ID") {
                    TextField("anthropic.claude-sonnet-4-6", text: $settings.bedrockModelId)
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SettingsView()
}
