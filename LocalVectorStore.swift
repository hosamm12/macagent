import Foundation
import SQLite3
import Accelerate

/// A simple on‑disk vector store that uses SQLite to persist embeddings and
/// provides cosine similarity search via Accelerate.  Each entry stores
/// arbitrary text, a fixed length embedding (as a binary blob), and optional
/// JSON metadata.  This class does not perform any compression or
/// approximate nearest neighbour indexing; for small to medium datasets
/// this naive approach is sufficiently performant on modern hardware.
public final class LocalVectorStore {
    private var db: OpaquePointer?

    /// Open (or create) a SQLite database at the given path.
    /// - Parameter path: File system path to the database file.  A new
    ///   database will be created if it does not already exist.
    public init(path: String) throws {
        if sqlite3_open(path, &db) != SQLITE_OK {
            throw NSError(domain: "LocalVectorStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to open database"])
        }
        try createTableIfNeeded()
    }

    deinit {
        sqlite3_close(db)
    }

    /// Insert or update a record in the database.  The text and embedding
    /// combination must be persisted together.  Metadata may be `nil` if
    /// there is no additional information to store.
    /// - Parameters:
    ///   - text: The original text.
    ///   - embedding: The vector embedding associated with the text.
    ///   - meta: An optional JSON‑encoded metadata string.
    public func upsert(text: String, embedding: [Float], meta: String? = nil) throws {
        let insertSQL = "INSERT INTO docs (text, emb, meta) VALUES (?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK else {
            throw currentError()
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, text, -1, SQLITE_TRANSIENT)
        // Bind embedding as blob
        embedding.withUnsafeBufferPointer { buffer in
            sqlite3_bind_blob(stmt, 2, buffer.baseAddress, Int32(buffer.count * MemoryLayout<Float>.size), SQLITE_TRANSIENT)
        }
        if let meta = meta {
            sqlite3_bind_text(stmt, 3, meta, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, 3)
        }
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw currentError()
        }
    }

    /// Retrieve the top `k` entries ranked by cosine similarity to the
    /// provided query vector.  All embeddings are assumed to be of equal
    /// dimension.  This method reads every row into memory to compute
    /// similarity; for large corpora consider adding an approximate index.
    /// - Parameters:
    ///   - query: The query embedding.
    ///   - k: The number of results to return.  Defaults to 5.
    /// - Returns: An array of hits containing the row id, original text and
    ///            similarity score, sorted descending by score.
    public func topK(query: [Float], k: Int = 5) throws -> [Hit] {
        let selectSQL = "SELECT id, text, emb FROM docs"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, selectSQL, -1, &stmt, nil) == SQLITE_OK else {
            throw currentError()
        }
        defer { sqlite3_finalize(stmt) }
        var hits: [Hit] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let text = String(cString: sqlite3_column_text(stmt, 1))
            guard let blob = sqlite3_column_blob(stmt, 2) else { continue }
            let bytes = sqlite3_column_bytes(stmt, 2)
            let count = Int(bytes) / MemoryLayout<Float>.size
            let pointer = blob.bindMemory(to: Float.self, capacity: count)
            let vec = Array(UnsafeBufferPointer(start: pointer, count: count))
            let score = cosine(query, vec)
            hits.append(Hit(id: id, text: text, score: score))
        }
        return hits.sorted(by: { $0.score > $1.score }).prefix(k).map { $0 }
    }

    /// Represent a similarity result.
    public struct Hit {
        public let id: Int64
        public let text: String
        public let score: Float
    }

    // MARK: - Private helpers

    private func createTableIfNeeded() throws {
        let sql = """
        CREATE TABLE IF NOT EXISTS docs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            emb BLOB NOT NULL,
            meta TEXT
        )
        """
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw currentError()
        }
    }

    private func currentError() -> NSError {
        let message = String(cString: sqlite3_errmsg(db))
        return NSError(domain: "LocalVectorStore", code: 2, userInfo: [NSLocalizedDescriptionKey: message])
    }

    /// Compute the cosine similarity of two equal‑length vectors using
    /// Accelerate's vDSP functions.
    private func cosine(_ a: [Float], _ b: [Float]) -> Float {
        let n = min(a.count, b.count)
        var dot: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        vDSP_dotpr(a, 1, b, 1, &dot, vDSP_Length(n))
        vDSP_svesq(a, 1, &normA, vDSP_Length(n))
        vDSP_svesq(b, 1, &normB, vDSP_Length(n))
        let denom = (sqrt(max(normA, 1e-9)) * sqrt(max(normB, 1e-9)))
        return dot / denom
    }
}