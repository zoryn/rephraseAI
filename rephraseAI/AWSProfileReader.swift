import Foundation

/// Reads AWS config from ~/.aws/config and resolves credentials via credential_process.
enum AWSProfileReader {

    struct Credentials {
        let accessKey: String
        let secretKey: String
        let sessionToken: String?
    }

    /// Resolve credentials for a profile by running its credential_process command.
    static func credentials(profile: String) throws -> Credentials {
        let configPath = NSString("~/.aws/config").expandingTildeInPath
        guard let sections = parseINI(path: configPath) else {
            throw AWSProfileError.configNotFound
        }

        let sectionName = profile == "default" ? "default" : "profile \(profile)"
        guard let section = sections[sectionName] else {
            throw AWSProfileError.profileNotFound(profile)
        }

        guard let command = section["credential_process"] else {
            throw AWSProfileError.noCredentialProcess(profile)
        }

        // Run the credential_process command
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw AWSProfileError.credentialProcessFailed(process.terminationStatus)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AWSProfileError.invalidCredentialOutput
        }

        // Standard credential_process output format:
        // { "Version": 1, "AccessKeyId": "...", "SecretAccessKey": "...", "SessionToken": "..." }
        guard let accessKey = json["AccessKeyId"] as? String,
              let secretKey = json["SecretAccessKey"] as? String
        else {
            throw AWSProfileError.invalidCredentialOutput
        }

        return Credentials(
            accessKey: accessKey,
            secretKey: secretKey,
            sessionToken: json["SessionToken"] as? String
        )
    }

    /// Read region for a given profile from ~/.aws/config
    static func region(profile: String) -> String? {
        let path = NSString("~/.aws/config").expandingTildeInPath
        guard let sections = parseINI(path: path) else { return nil }

        let sectionName = profile == "default" ? "default" : "profile \(profile)"
        return sections[sectionName]?["region"]
    }

    // MARK: - INI Parser

    private static func parseINI(path: String) -> [String: [String: String]]? {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }

        var sections: [String: [String: String]] = [:]
        var currentSection = ""

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix(";") {
                continue
            }

            if trimmed.hasPrefix("["), trimmed.hasSuffix("]") {
                currentSection = String(trimmed.dropFirst().dropLast())
                    .trimmingCharacters(in: .whitespaces)
                if sections[currentSection] == nil {
                    sections[currentSection] = [:]
                }
                continue
            }

            if let eqIndex = trimmed.firstIndex(of: "=") {
                let key = trimmed[trimmed.startIndex..<eqIndex]
                    .trimmingCharacters(in: .whitespaces)
                let value = trimmed[trimmed.index(after: eqIndex)...]
                    .trimmingCharacters(in: .whitespaces)
                sections[currentSection, default: [:]][key] = value
            }
        }

        return sections
    }
}

enum AWSProfileError: LocalizedError {
    case configNotFound
    case profileNotFound(String)
    case noCredentialProcess(String)
    case credentialProcessFailed(Int32)
    case invalidCredentialOutput

    var errorDescription: String? {
        switch self {
        case .configNotFound:
            return "~/.aws/config not found"
        case .profileNotFound(let name):
            return "Profile '\(name)' not found in ~/.aws/config"
        case .noCredentialProcess(let name):
            return "No credential_process defined for profile '\(name)' in ~/.aws/config"
        case .credentialProcessFailed(let code):
            return "credential_process exited with code \(code)"
        case .invalidCredentialOutput:
            return "credential_process returned invalid JSON"
        }
    }
}
