import AppIntents
import Foundation
import AgentCore

/// Perform a web search using a specified search engine and query string.
///
/// The default search engine is Google, but users can supply any engine
/// URL prefix that accepts a `q` parameter.  The intent percent‑encodes
/// the query and delegates to the adapter.
struct WebSearchIntent: AppIntent {
    static var title: LocalizedStringResource = "Web Search"
    static var description = IntentDescription("Search the web using a given search engine and query term.")

    @Parameter(title: "Engine", default: "https://www.google.com/search?q=")
    var engine: String

    @Parameter(title: "Query")
    var query: String

    static var parameterSummary: some ParameterSummary {
        Summary("Search \(\.$engine) for \(\.$query)")
    }

    func perform() async throws -> some IntentResult {
        guard let engineURL = URL(string: engine) else {
            throw IntentError("Invalid search engine URL.")
        }
        PlatformAdapter.shared.webSearch(engine: engineURL, query: query)
        return .result()
    }
}