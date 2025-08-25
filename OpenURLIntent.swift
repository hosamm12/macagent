import AppIntents
import Foundation
import AgentCore

/// An intent that opens a specified URL in Safari.
///
/// Users can invoke this via Siri or search by saying “افتح الرابط…”
/// and providing a URL.  The intent validates the URL string and then
/// delegates to the shared `AppleAdapter` to perform the navigation.
struct OpenURLIntent: AppIntent {
    static var title: LocalizedStringResource = "Open URL"
    static var description = IntentDescription("Open a web page in Safari using the provided URL.")

    @Parameter(title: "URL", description: "The full web address to open.")
    var urlString: String

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$urlString)")
    }

    func perform() async throws -> some IntentResult {
        guard let url = URL(string: urlString) else {
            throw IntentError("Invalid URL.")
        }
        PlatformAdapter.shared.openURL(url)
        return .result()
    }
}