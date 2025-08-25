import Foundation
import CoreML

/// A thin wrapper around a Core ML model that produces vector embeddings
/// from input text.  Initialise this engine with the compiled model URL
/// and the appropriate input and output feature names.  You can then call
/// `embed(_:)` to obtain an array of `Float` representing the embedding.
public final class EmbeddingsEngine {
    private let model: MLModel
    private let inputName: String
    private let outputName: String

    /// Create a new embeddings engine.
    /// - Parameters:
    ///   - modelURL: The URL of the compiled `.mlmodelc` directory.
    ///   - inputName: The name of the text input feature (default: "text").
    ///   - outputName: The name of the embedding output feature (default: "embedding").
    public init(modelURL: URL, inputName: String = "text", outputName: String = "embedding") throws {
        self.model = try MLModel(contentsOf: modelURL)
        self.inputName = inputName
        self.outputName = outputName
    }

    /// Generate an embedding for the provided text.
    /// - Parameter text: The string to embed.
    /// - Returns: An array of floats representing the embedding.
    /// - Throws: If the model prediction fails or the output cannot be
    ///   interpreted as a floating‑point multi‑array.
    public func embed(_ text: String) throws -> [Float] {
        let inputProvider = try MLDictionaryFeatureProvider(dictionary: [inputName: text])
        let prediction = try model.prediction(from: inputProvider)
        guard let array = prediction.featureValue(for: outputName)?.multiArrayValue else {
            throw NSError(domain: "EmbeddingsEngine", code: 0, userInfo: [NSLocalizedDescriptionKey: "Embedding output missing"])
        }
        // Flatten the MLMultiArray into a Swift array of Float.
        let count = array.count
        var result: [Float] = []
        result.reserveCapacity(count)
        for i in 0..<count {
            let value = array[i]
            result.append(Float(truncating: value))
        }
        return result
    }
}