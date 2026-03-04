import Foundation
import CryptoKit

/// AWS Signature Version 4 signer for Bedrock API requests.
struct AWSSignature {

    let accessKey: String
    let secretKey: String
    let sessionToken: String?
    let region: String
    let service: String

    /// Signs a URLRequest in place by adding Authorization, X-Amz-Date, and related headers.
    func sign(_ request: inout URLRequest, date: Date = Date()) {
        let (amzDate, dateStamp) = formattedDates(date)

        // Required headers
        let host = request.url!.host!
        request.setValue(host, forHTTPHeaderField: "Host")
        request.setValue(amzDate, forHTTPHeaderField: "X-Amz-Date")

        let payloadHash = sha256Hex(request.httpBody ?? Data())
        request.setValue(payloadHash, forHTTPHeaderField: "x-amz-content-sha256")

        if let sessionToken {
            request.setValue(sessionToken, forHTTPHeaderField: "X-Amz-Security-Token")
        }

        // Build sorted list of headers to sign
        let headersToSign = ["content-type", "host", "x-amz-content-sha256", "x-amz-date"]
            + (sessionToken != nil ? ["x-amz-security-token"] : [])
        let signedHeaders = headersToSign.sorted().joined(separator: ";")

        let canonicalHeaders = headersToSign.sorted().map { name in
            let value = request.value(forHTTPHeaderField: name) ?? ""
            return "\(name):\(value.trimmingCharacters(in: .whitespaces))"
        }.joined(separator: "\n") + "\n"

        // Canonical request
        let method = request.httpMethod ?? "POST"
        let canonicalURI = request.url!.path.isEmpty ? "/" : request.url!.path
        let canonicalQueryString = request.url?.query ?? ""

        let canonicalRequest = [
            method,
            canonicalURI,
            canonicalQueryString,
            canonicalHeaders,
            signedHeaders,
            payloadHash
        ].joined(separator: "\n")

        // String to sign
        let credentialScope = "\(dateStamp)/\(region)/\(service)/aws4_request"
        let stringToSign = [
            "AWS4-HMAC-SHA256",
            amzDate,
            credentialScope,
            sha256Hex(Data(canonicalRequest.utf8))
        ].joined(separator: "\n")

        // Derive signing key
        let kDate    = hmacSHA256(key: Data("AWS4\(secretKey)".utf8), data: Data(dateStamp.utf8))
        let kRegion  = hmacSHA256(key: kDate, data: Data(region.utf8))
        let kService = hmacSHA256(key: kRegion, data: Data(service.utf8))
        let kSigning = hmacSHA256(key: kService, data: Data("aws4_request".utf8))

        // Final signature
        let signature = hmacSHA256(key: kSigning, data: Data(stringToSign.utf8))
            .map { String(format: "%02x", $0) }
            .joined()

        let authorization = "AWS4-HMAC-SHA256 Credential=\(accessKey)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
    }

    // MARK: - Helpers

    private func formattedDates(_ date: Date) -> (amzDate: String, dateStamp: String) {
        let fmt = DateFormatter()
        fmt.timeZone = TimeZone(identifier: "UTC")
        fmt.locale = Locale(identifier: "en_US_POSIX")

        fmt.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        let amzDate = fmt.string(from: date)

        fmt.dateFormat = "yyyyMMdd"
        let dateStamp = fmt.string(from: date)

        return (amzDate, dateStamp)
    }

    private func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func hmacSHA256(key: Data, data: Data) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: data, using: SymmetricKey(data: key)))
    }
}
