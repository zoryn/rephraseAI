import Foundation
import Observation

@Observable
class SettingsModel {

    static let shared = SettingsModel()

    private static let defaultPrompt = "Refine and improve the following text. Preserve the original meaning and tone. Return only the refined text, without any explanation or commentary."

    private init() {
        if defaults.data(forKey: "modes") == nil {
            let prompt = defaults.string(forKey: "customPrompt") ?? Self.defaultPrompt
            let defaultMode = Mode(title: "Refine", prompt: prompt)
            defaults.set(try? JSONEncoder().encode([defaultMode]), forKey: "modes")
            defaults.set(defaultMode.id.uuidString, forKey: "activeModeId")
        }
    }

    enum Provider: String, CaseIterable, Identifiable {
        case claude = "claude"
        case openai = "openai"
        case bedrock = "bedrock"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .claude: return "Claude (Anthropic)"
            case .openai: return "OpenAI (GPT-4o)"
            case .bedrock: return "AWS Bedrock"
            }
        }
    }

    private let defaults = UserDefaults.standard

    var provider: Provider {
        get {
            access(keyPath: \.provider)
            return Provider(rawValue: defaults.string(forKey: "provider") ?? "") ?? .claude
        }
        set {
            withMutation(keyPath: \.provider) {
                defaults.set(newValue.rawValue, forKey: "provider")
            }
        }
    }

    var customPrompt: String {
        get {
            access(keyPath: \.customPrompt)
            return defaults.string(forKey: "customPrompt")
                ?? "Refine and improve the following text. Preserve the original meaning and tone. Return only the refined text, without any explanation or commentary."
        }
        set {
            withMutation(keyPath: \.customPrompt) {
                defaults.set(newValue, forKey: "customPrompt")
            }
        }
    }

    var anthropicApiKey: String {
        get {
            access(keyPath: \.anthropicApiKey)
            return KeychainManager.load(key: "anthropicApiKey") ?? ""
        }
        set {
            withMutation(keyPath: \.anthropicApiKey) {
                KeychainManager.save(key: "anthropicApiKey", value: newValue)
            }
        }
    }

    var openaiApiKey: String {
        get {
            access(keyPath: \.openaiApiKey)
            return KeychainManager.load(key: "openaiApiKey") ?? ""
        }
        set {
            withMutation(keyPath: \.openaiApiKey) {
                KeychainManager.save(key: "openaiApiKey", value: newValue)
            }
        }
    }

    // MARK: - AWS Bedrock

    var awsProfile: String {
        get {
            access(keyPath: \.awsProfile)
            return defaults.string(forKey: "awsProfile") ?? "default"
        }
        set {
            withMutation(keyPath: \.awsProfile) {
                defaults.set(newValue, forKey: "awsProfile")
            }
        }
    }

    var bedrockModelId: String {
        get {
            access(keyPath: \.bedrockModelId)
            return defaults.string(forKey: "bedrockModelId") ?? "us.anthropic.claude-opus-4-6-v1"
        }
        set {
            withMutation(keyPath: \.bedrockModelId) {
                defaults.set(newValue, forKey: "bedrockModelId")
            }
        }
    }

    // MARK: - Modes

    var modes: [Mode] {
        get {
            access(keyPath: \.modes)
            guard let data = defaults.data(forKey: "modes") else { return [] }
            return (try? JSONDecoder().decode([Mode].self, from: data)) ?? []
        }
        set {
            withMutation(keyPath: \.modes) {
                defaults.set(try? JSONEncoder().encode(newValue), forKey: "modes")
            }
        }
    }

    var activeModeId: UUID? {
        get {
            access(keyPath: \.activeModeId)
            guard let str = defaults.string(forKey: "activeModeId") else { return nil }
            return UUID(uuidString: str)
        }
        set {
            withMutation(keyPath: \.activeModeId) {
                defaults.set(newValue?.uuidString, forKey: "activeModeId")
            }
        }
    }

    var effectivePrompt: String {
        if let activeId = activeModeId,
           let mode = modes.first(where: { $0.id == activeId }) {
            return mode.prompt
        }
        return Self.defaultPrompt
    }

    var activeModeName: String? {
        guard let activeId = activeModeId else { return nil }
        return modes.first(where: { $0.id == activeId })?.title
    }
}
