import AppIntents
import Foundation
import AgentCore

/// Scan a directory for source/text files and produce file reports on the
/// Desktop.  See `AppleAdapter.scanAndCollect(baseName:)` for details.
struct ScanCollectIntent: AppIntent {
    static var title: LocalizedStringResource = "Scan & Collect"
    static var description = IntentDescription("Scan a selected folder for text files, compute checksums, and write reports to the Desktop.")

    @Parameter(title: "Output Base Name", default: "AgentScan")
    var baseName: String

    static var parameterSummary: some ParameterSummary {
        Summary("Scan and collect as \(\.$baseName)")
    }

    func perform() async throws -> some IntentResult {
        PlatformAdapter.shared.scanAndCollect(baseName: baseName)
        return .result()
    }
}