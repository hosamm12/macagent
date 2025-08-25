# Build an AI Agent for macOS with Siri and Core ML

@Metadata {
  @Documentation(title: "Build an AI Agent for macOS with Siri and Core ML", summary: "Learn how to create a simple intelligent assistant on macOS using App Intents, Apple Events, Core ML and local vector search. This tutorial shows how to configure a new Xcode project, define intents for Siri, implement an adapter for safe system interaction, add a basic retrieval‑augmented memory and document your code with DocC.")
  @PageImage(purpose: card, source: "cover.png")
  @PageBackground(color: {light: "#F8F8F8", dark: "#1A1A1A"})
}

## Overview

In this tutorial you will build **AgentMac**, a small macOS app that listens
to your Siri commands and performs actions on your behalf.  The project
demonstrates several Apple technologies working together:

* **App Intents** provide a way to expose actions to Siri, Spotlight and
  Shortcuts.  You will create intents for opening URLs, searching the web,
  finding emails, running Shortcuts and scanning a folder of text files.
* **Apple Events** let the app control Safari and Mail securely.  The
  `AppleAdapter` class wraps these calls so your business logic remains
  platform‑agnostic.
* **Core ML**, **SQLite** and **Accelerate** implement a simple
  retrieval‑augmented memory (RAG).  Every command can be embedded into a
  vector and stored; later commands can query this vector store for
  suggestions.
* **DocC** generates beautiful documentation right inside Xcode.

## Set up the Xcode project

Before diving into code, create a new SwiftUI app in Xcode:

1. Open **Xcode 26** and choose **File ▸ New ▸ Project…**.  Select **App**
   under the **macOS** tab and click *Next*.
2. Name the product **AgentMac** and ensure **Swift** and **SwiftUI** are
   selected.  Click *Next* to create the project.
3. Add a new **App Intents Extension** target via **File ▸ New ▸ Target…**
   and choose **App Intents Extension**.  This will host your intent
   definitions.
4. In the main app target, enable **App Sandbox** and **Hardened Runtime**
   in **Signing & Capabilities**.  Add the **Apple Events** capability so
   your app can send events to Safari and Mail.  In `Info.plist` provide
   a `NSAppleEventsUsageDescription` explaining why the app needs this.

## Define the adapter

Create a new Swift package called **AgentCore** to host platform‑agnostic
code.  Inside it define an `AppleAdapter` protocol and implement
`AppleAdapterImpl` for macOS.  The adapter encapsulates all system
interactions: opening URLs in Safari, performing web searches, selecting
Mail messages, running Shortcuts and scanning directories.  By funnelling
all side effects through this adapter, the rest of your code remains
testable and portable.

```swift
// AppleAdapter.swift
public protocol AppleAdapter {
  func openURL(_ url: URL)
  func webSearch(engine: URL, query: String)
  func mailSearch(senderContains: String, contentContains: String, activate: Bool)
  func runShortcut(_ name: String, input: String?)
  func scanAndCollect(baseName: String)
}

// AppleAdapterImpl.swift
final class AppleAdapterImpl: AppleAdapter {
  func openURL(_ url: URL) {
    let script = """
    tell application \"Safari\"
      activate
      make new document with properties {URL:\(url.absoluteString)}
    end tell
    """
    runOSA(script)
  }
  // Remaining methods use AppleScript or the `shortcuts` command line tool.
}
```

## Create App Intents

In your App Intents extension, define a struct for each action you want
Siri to perform.  Each intent declares parameters, a summary and a
`perform()` method that delegates to the adapter.  Examples:

```swift
struct WebSearchIntent: AppIntent {
  static var title = "Web Search"
  @Parameter var engine: String = "https://www.google.com/search?q="
  @Parameter var query: String
  func perform() async throws -> some IntentResult {
    guard let engineURL = URL(string: engine) else { throw IntentError("Invalid engine") }
    PlatformAdapter.shared.webSearch(engine: engineURL, query: query)
    return .result()
  }
}

struct MailSearchIntent: AppIntent {
  @Parameter var sender: String
  @Parameter var content: String
  @Parameter var activate: Bool = true
  func perform() async throws -> some IntentResult {
    PlatformAdapter.shared.mailSearch(senderContains: sender, contentContains: content, activate: activate)
    return .result()
  }
}
```

Once these intents are built, Siri will be able to resolve natural
language into parameters and call your code.

## Add a retrieval memory (optional)

To make your agent smarter over time you can embed each command and
store it in a vector database.  Create an `EmbeddingsEngine` that wraps
a Core ML model, and a `LocalVectorStore` that uses SQLite and
Accelerate to persist and search embeddings.  After executing an
intent, call `saveTask(text:)` to store it.  When receiving a new
command, compute its embedding and query `topK()` to retrieve similar
previous tasks for suggestions.

```swift
let engine = try EmbeddingsEngine(modelURL: modelURL)
let store = try LocalVectorStore(path: dbPath)
let vector = try engine.embed(userQuery)
let results = try store.topK(query: vector, k: 5)
```

## Generate documentation

Finally, create a documentation catalog in Xcode via **File ▸ New ▸ File…**
and choose **Documentation Catalog**.  Inside it, author a Markdown
tutorial like this one.  Use DocC directives (`@Section`, `@Step`) to
break down your explanation.  Build the documentation with
**Product ▸ Build Documentation** and explore it in Xcode’s DocC viewer.

## Conclusion

You’ve built a simple yet powerful AI agent for macOS by combining
Siri/App Intents, Apple Events, Core ML and SQLite.  With a modular
adapter and optional RAG memory, AgentMac can grow over time to
include additional actions, a more advanced planner and deeper
integration with system services.  For more information on the
technologies used here, consult the official Apple Developer
documentation.