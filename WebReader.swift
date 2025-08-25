import Foundation
import WebKit

/// A lightweight wrapper around WKWebView for loading web pages and extracting
/// visible text.  This helper is optional; it is only used when the agent
/// needs to parse the contents of a page locally rather than delegate to
/// Safari.  Because WKWebView is only available on macOS 10.10+, this
/// helper should be referenced conditionally to preserve compatibility.
public final class WebReader: NSObject, WKNavigationDelegate {
    private let webView: WKWebView

    /// Create a new WebReader with a default WKWebView configuration.
    public override init() {
        self.webView = WKWebView(frame: .zero)
        super.init()
        webView.navigationDelegate = self
    }

    /// Load the given URL in the internal WKWebView.  Completion handlers
    /// will be invoked once navigation finishes (or fails).
    /// - Parameter url: The URL to load.
    public func load(_ url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    /// Extract a summary of textual content from the current page.  This
    /// method runs a JavaScript snippet that collects the innerText of a
    /// selection of elements and concatenates them.  The completion
    /// handler receives the resulting string.
    /// - Parameter completion: A closure called with the extracted text.
    public func extractText(completion: @escaping (String) -> Void) {
        let js = """
        [...document.querySelectorAll('h1,h2,h3,a,p,span,div')]
          .slice(0, 200)
          .map(e => e.innerText)
          .join('\n')
        """
        webView.evaluateJavaScript(js) { result, error in
            if let text = result as? String {
                completion(text)
            } else {
                completion("")
            }
        }
    }

    // WKNavigationDelegate stub: handle errors quietly.
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // We deliberately ignore navigation errors here; the caller should
        // implement its own error handling if needed.
    }
}