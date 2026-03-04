import Foundation

struct BedrockService: LLMService {

    func refine(_ text: String) async throws -> String {
        let settings = SettingsModel.shared
        let profile = settings.awsProfile.isEmpty ? "default" : settings.awsProfile

        // Run credential_process from ~/.aws/config
        let creds = try AWSProfileReader.credentials(profile: profile)

        // Read region from ~/.aws/config, fall back to us-east-1
        let region = AWSProfileReader.region(profile: profile) ?? "us-east-1"
        let modelId = settings.bedrockModelId.isEmpty
            ? "us.anthropic.claude-sonnet-4-6-v1"
            : settings.bedrockModelId

        // Bedrock InvokeModel endpoint — uses Anthropic Messages format for Claude
        let encodedModelId = modelId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? modelId
        let url = URL(string: "https://bedrock-runtime.\(region).amazonaws.com/model/\(encodedModelId)/invoke")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("application/json", forHTTPHeaderField: "accept")

        // Anthropic Messages API body format (used by Claude on Bedrock)
        let body: [String: Any] = [
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 4096,
            "system": settings.customPrompt,
            "messages": [
                ["role": "user", "content": text]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Sign with AWS SigV4
        let signer = AWSSignature(
            accessKey: creds.accessKey,
            secretKey: creds.secretKey,
            sessionToken: creds.sessionToken,
            region: region,
            service: "bedrock"
        )
        signer.sign(&request)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                throw LLMError.apiError(message)
            }
            throw LLMError.httpError(httpResponse.statusCode)
        }

        // Response is same Anthropic Messages format
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let result = firstBlock["text"] as? String
        else { throw LLMError.invalidResponse }

        return result
    }
}
