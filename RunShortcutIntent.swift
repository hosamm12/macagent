import AppIntents
import Foundation
import AgentCore

/// Execute a preconfigured macOS Shortcut by name, optionally with input.
///
/// The user must have created the Shortcut beforehand.  The name is
/// case‑sensitive.  Input can be any string; if omitted no input is
/// provided.  Successful execution of a Shortcut does not return any
/// result value to the user.
struct RunShortcutIntent: AppIntent {
    static var title: LocalizedStringResource = "Run Shortcut"
    static var description = IntentDescription("Run one of your installed Shortcuts, optionally passing input text.")

    @Parameter(title: "Name")
    var name: String

    @Parameter(title: "Input", description: "Optional text input for the Shortcut.")
    var input: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Run Shortcut \(\.$name)")
    }

    func perform() async throws -> some IntentResult {
        PlatformAdapter.shared.runShortcut(name, input: input)
        return .result()
    }
}