import Foundation

protocol LLMService {
    func refine(_ text: String) async throws -> String
}

enum LLMError: LocalizedError {
    case missingApiKey(String)
    case httpError(Int)
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingApiKey(let provider):
            return "No API key set for \(provider). Open Settings to add one."
        case .httpError(let code):
            return "HTTP error \(code) from LLM API."
        case .invalidResponse:
            return "Unexpected response format from LLM API."
        case .apiError(let message):
            return "LLM API error: \(message)"
        }
    }
}

enum LLMServiceFactory {
    static func make() -> LLMService {
        switch SettingsModel.shared.provider {
        case .claude:  return AnthropicService()
        case .openai:  return OpenAIService()
        case .bedrock: return BedrockService()
        }
    }
}
