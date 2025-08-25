import Foundation
import AppKit
import CryptoKit

/// Default macOS implementation of `AppleAdapter`.
///
/// This class encapsulates all privileged operations used by the agent.  It
/// relies on Apple Events (via `osascript`) to control Safari and Mail and
/// uses the `shortcuts` command line tool to run Shortcuts.  File
/// scanning and reporting are implemented using Foundation and CryptoKit.
final class AppleAdapterImpl: AppleAdapter {
    func openURL(_ url: URL) {
        // Use AppleScript to open Safari and navigate to the provided URL.
        let script = """
        tell application "Safari"
          activate
          make new document with properties {URL:\(url.absoluteString)}
        end tell
        """
        runOSA(script)
    }

    func webSearch(engine: URL, query: String) {
        // Percent‑encode the query and append it to the engine URL.  Then
        // delegate to openURL(_:) to perform the navigation.
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let searchURL = URL(string: engine.absoluteString + encoded) else { return }
        openURL(searchURL)
    }

    func mailSearch(senderContains: String, contentContains: String, activate: Bool) {
        // Escape quotes in strings for safe embedding in AppleScript.
        let senderEsc = senderContains.replacingOccurrences(of: "\"", with: "\\\"")
        let contentEsc = contentContains.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Mail"
          set msgs to (messages of inbox whose sender contains "\(senderEsc)" and content contains "\(contentEsc)")
          if (count of msgs) > 0 then
            set m to item 1 of msgs
            set selected messages of message viewer 1 to {m}
            if \(activate ? "true" : "false") then activate
          end if
        end tell
        """
        runOSA(script)
    }

    func runShortcut(_ name: String, input: String?) {
        // Use the `shortcuts` command line tool to run a named shortcut.
        var args = ["run", name]
        if let input = input, !input.isEmpty {
            args += ["--input", input]
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = args
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            // Ignore errors to keep the agent resilient.
        }
    }

    func scanAndCollect(baseName: String) {
        // Prompt the user to select a directory to scan.
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        guard panel.runModal() == .OK, let rootURL = panel.url else { return }
        // Acquire security scope for sandboxed access.
        guard rootURL.startAccessingSecurityScopedResource() else { return }
        defer { rootURL.stopAccessingSecurityScopedResource() }

        // Enumerate allowed file types.
        let fm = FileManager.default
        let allowedExtensions: Set<String> = ["swift", "sh", "py", "txt", "json", "yml"]
        var files: [(URL, Data)] = []
        if let enumerator = fm.enumerator(at: rootURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                guard allowedExtensions.contains(fileURL.pathExtension.lowercased()) else { continue }
                if let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]), values.isRegularFile == true {
                    if let data = try? Data(contentsOf: fileURL) {
                        files.append((fileURL, data))
                    }
                }
            }
        }
        // Compute records and identify duplicates.
        struct Record: Codable {
            let path: String
            let sha: String
            let size: Int
        }
        func sha256(_ data: Data) -> String {
            let digest = SHA256.hash(data: data)
            return digest.map { String(format: "%02x", $0) }.joined()
        }
        var allRecords: [Record] = []
        var firstByHash: [String: Record] = [:]
        var duplicates: [(Record, Record)] = []
        for (url, data) in files {
            let hash = sha256(data)
            let record = Record(path: url.path, sha: hash, size: data.count)
            allRecords.append(record)
            if let existing = firstByHash[hash] {
                duplicates.append((existing, record))
            } else {
                firstByHash[hash] = record
            }
        }
        // Prepare output directory on Desktop.
        let desktop = fm.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        // Manifest JSON listing all scanned files.
        let manifestURL = desktop.appendingPathComponent("\(baseName)_Manifest.json")
        if let json = try? JSONEncoder().encode(allRecords) {
            try? json.write(to: manifestURL)
        }
        // Concatenation of unique file contents.
        var uniqueConcat = ""
        for record in firstByHash.values.sorted(by: { $0.path < $1.path }) {
            uniqueConcat += "\n\n===== FILE: \(record.path) | SHA256: \(record.sha) | SIZE: \(record.size) =====\n"
            let contents: String
            do {
                contents = try String(contentsOfFile: record.path)
            } catch {
                contents = "<BINARY>"
            }
            uniqueConcat += contents
        }
        let uniqueURL = desktop.appendingPathComponent("\(baseName)_All_Unique.txt")
        try? uniqueConcat.data(using: .utf8)?.write(to: uniqueURL)
        // CSV of duplicates (original and duplicate file pairs).
        var csv = "orig_path,orig_sha,dup_path,dup_sha\n"
        for (orig, dup) in duplicates {
            csv += "\"\(orig.path)\",\(orig.sha),\"\(dup.path)\",\(dup.sha)\n"
        }
        let duplicatesURL = desktop.appendingPathComponent("\(baseName)_Duplicates.csv")
        try? csv.data(using: .utf8)?.write(to: duplicatesURL)
    }

    // Helper to execute an AppleScript string via the system `osascript` utility.
    private func runOSA(_ script: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            // Swallow errors to avoid crashing the agent; failure here simply
            // means the Apple Event could not be sent.
        }
    }
}