# rephraseAI

Native macOS menu bar app that refines selected text in any application using an LLM.

## How It Works

1. User selects text in any app
2. Presses global hotkey (⌘⇧Space)
3. App copies the selection, sends it to the configured LLM, and pastes back the refined text
4. Original clipboard contents are restored

## Architecture

- **Swift + SwiftUI + AppKit** hybrid — SwiftUI for settings UI, AppKit for menu bar and window management
- **App Sandbox disabled** — required for CGEventPost (simulating Cmd+C/V)
- **No third-party dependencies** — uses Foundation, CryptoKit, Carbon, Security frameworks only

## Key Files
| File | Purpose |
|------|---------|
| `rephraseAIApp.swift` | App entry point, NSApplicationDelegateAdaptor |
| `AppDelegate.swift` | Menu bar (NSStatusItem), settings window, processing state |
| `HotkeyManager.swift` | Global hotkey via Carbon RegisterEventHotKey |
| `TextProcessor.swift` | Orchestrates copy → LLM → paste flow |
| `ClipboardManager.swift` | Cmd+C/V simulation via CGEventPost, clipboard save/restore |
| `LLMService.swift` | Protocol + factory for LLM providers |
| `AnthropicService.swift` | Claude API (claude-sonnet-4-6) |
| `OpenAIService.swift` | OpenAI API (gpt-4o) |
| `BedrockService.swift` | AWS Bedrock via InvokeModel with SigV4 signing |
| `AWSSignature.swift` | AWS SigV4 signing using CryptoKit |
| `AWSProfileReader.swift` | Parses ~/.aws/config, runs credential_process |
| `KeychainManager.swift` | Keychain CRUD for API keys |
| `SettingsModel.swift` | @Observable settings backed by UserDefaults + Keychain |
| `SettingsView.swift` | TabView settings UI (General, Anthropic, OpenAI, Bedrock) |

All source files are in `rephraseAI/rephraseAI/`.

## LLM Providers

- **Anthropic Claude** — direct API, key stored in Keychain
- **OpenAI GPT-4o** — direct API, key stored in Keychain
- **AWS Bedrock** — uses credential_process from ~/.aws/config, SigV4 signed requests

## Build & Run

Open `rephraseAI.xcodeproj` in Xcode and build (⌘B). The app requires Accessibility permission (System Settings → Privacy & Security → Accessibility).

## Conventions

- No third-party packages — keep dependencies at zero
- API keys go in Keychain (via KeychainManager), other settings in UserDefaults
- Each LLM provider conforms to the `LLMService` protocol
- Settings UI uses one tab per provider
