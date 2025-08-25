import Foundation

/// A protocol defining safe high‑level operations for controlling macOS apps.
///
/// Implementations of this protocol should encapsulate all privileged
/// interactions with the system and external applications.  Exposed methods
/// provide a small set of capabilities—opening URLs, performing web searches,
/// selecting messages in Mail, running Shortcuts, and scanning a directory
/// for text files.  By funneling all side effects through this interface, the
/// rest of the agent remains easy to reason about and secure.
public protocol AppleAdapter {
    /// Open the provided URL in Safari.  This method should use Apple Events
    /// on macOS to request Safari create a new tab and navigate to the URL.
    /// - Parameter url: An absolute URL to open.
    func openURL(_ url: URL)

    /// Perform a web search using a specific search engine and query.  The
    /// adapter is responsible for encoding the query string and constructing
    /// the final URL.  On macOS this will ultimately call `openURL(_:)`.
    /// - Parameters:
    ///   - engine: The base URL of the search engine (for example,
    ///             `https://www.google.com/search?q=`).
    ///   - query: The search terms to append to the engine URL.
    func webSearch(engine: URL, query: String)

    /// Find the first message in the user’s Mail inbox matching the given
    /// criteria and select it.  Implementations should use the Mail Apple
    /// Events API.  If `activate` is `true`, Mail will become the frontmost
    /// application.
    /// - Parameters:
    ///   - senderContains: A substring to match against the message sender.
    ///   - contentContains: A substring to match against the message body.
    ///   - activate: Whether to bring Mail to the foreground after selection.
    func mailSearch(senderContains: String, contentContains: String, activate: Bool)

    /// Run an installed Shortcuts automation by name.  Optionally pass a
    /// free‑form input string.  This relies on the `shortcuts` command line
    /// utility provided by macOS.
    /// - Parameters:
    ///   - name: The name of the Shortcut to run.
    ///   - input: Optional text to pass as input to the Shortcut.
    func runShortcut(_ name: String, input: String?)

    /// Scan a user‑selected directory for plain text source files (.swift,
    /// .sh, .py, .txt, .json and .yml).  Compute a SHA‑256 checksum for each
    /// file and write three reports to the user’s Desktop: a manifest of all
    /// files, a concatenation of unique file contents, and a CSV listing
    /// duplicates.  Implementations should use NSOpenPanel to prompt for
    /// directory selection and write results using the Security Scoped
    /// Resource API.
    /// - Parameter baseName: A base name for the generated report files.
    func scanAndCollect(baseName: String)
}

/// Convenience access to a shared adapter instance.  This indirection
/// simplifies dependency injection in contexts (App Intents, UI) that do not
/// support property injection.
public enum PlatformAdapter {
    /// Shared adapter implementation for the current platform (macOS).  For
    /// additional platforms this could return different implementations.
    public static let shared: AppleAdapter = AppleAdapterImpl()
}