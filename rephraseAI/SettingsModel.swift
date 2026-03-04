import Foundation
import Observation

@Observable
class SettingsModel {

    static let shared = SettingsModel()

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
            Provider(rawValue: defaults.string(forKey: "provider") ?? "") ?? .claude
        }
        set {
            defaults.set(newValue.rawValue, forKey: "provider")
        }
    }

    var customPrompt: String {
        get {
            defaults.string(forKey: "customPrompt")
                ?? "Refine and improve the following text. Preserve the original meaning and tone. Return only the refined text, without any explanation or commentary."
        }
        set {
            defaults.set(newValue, forKey: "customPrompt")
        }
    }

    var anthropicApiKey: String {
        get { KeychainManager.load(key: "anthropicApiKey") ?? "" }
        set { KeychainManager.save(key: "anthropicApiKey", value: newValue) }
    }

    var openaiApiKey: String {
        get { KeychainManager.load(key: "openaiApiKey") ?? "" }
        set { KeychainManager.save(key: "openaiApiKey", value: newValue) }
    }

    // MARK: - AWS Bedrock

    var awsProfile: String {
        get { defaults.string(forKey: "awsProfile") ?? "default" }
        set { defaults.set(newValue, forKey: "awsProfile") }
    }

    var bedrockModelId: String {
        get { defaults.string(forKey: "bedrockModelId") ?? "us.anthropic.claude-opus-4-6-v1" }
        set { defaults.set(newValue, forKey: "bedrockModelId") }
    }
}
