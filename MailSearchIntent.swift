import AppIntents
import Foundation
import AgentCore

/// Search the Mail inbox for messages matching sender and content filters.
///
/// When invoked, the first message matching both filters will be selected
/// in Mail.  Users can optionally choose whether Mail should be brought
/// to the front after selection.
struct MailSearchIntent: AppIntent {
    static var title: LocalizedStringResource = "Mail Search"
    static var description = IntentDescription("Find the first email in your inbox that matches the specified sender and content snippets.")

    @Parameter(title: "Sender contains", description: "Part of the sender’s name or email address to match.")
    var sender: String

    @Parameter(title: "Content contains", description: "Part of the message body to match.")
    var content: String

    @Parameter(title: "Activate Mail", default: true, description: "Whether to bring the Mail app to the front after selection.")
    var activate: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Find email from \(\.$sender) containing \(\.$content)")
    }

    func perform() async throws -> some IntentResult {
        PlatformAdapter.shared.mailSearch(senderContains: sender, contentContains: content, activate: activate)
        return .result()
    }
}