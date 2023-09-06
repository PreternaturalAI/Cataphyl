//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import FoundationX
import Swallow

public protocol PlainTextDocumentProtocol: _ContiguousChunkableDocument, CustomTextConvertible where Chunk.Span == PlainTextDocument.Chunk.Span, Chunk.ID == PlainTextDocument.Chunk.ID, Chunk: CustomTextConvertible {
    var text: String { get throws }
    
    subscript(
        span: PlainTextDocument.Chunk.Span
    ) -> PlainTextDocument.Chunk { get throws }
    
    func chunk(for span: PlainTextDocument.Chunk.Span) throws -> PlainTextDocument.Chunk
}

// MARK: - Implementation

extension PlainTextDocumentProtocol where Chunk == PlainTextDocument.Chunk {
    public subscript(
        span: Chunk.Span
    ) -> Chunk {
        get throws {
            guard let first = span.rawValue.first, let last = span.rawValue.last else {
                throw _PlaceholderError()
            }
            
            return .init(text: String(try text[from: first, to: last]), span: span)
        }
    }
     
    public func chunk(for span: PlainTextDocument.Chunk.Span) throws -> PlainTextDocument.Chunk {
        try self[span]
    }
}

extension PlainTextDocumentProtocol where Self: CustomStringConvertible {
    public var description: String {
        (try? text) ?? "<error>"
    }
}

extension String {
    subscript(
        from first: PlainTextDocument.TextRange,
        to second: PlainTextDocument.TextRange
    ) -> Substring {
        get throws {
            switch (first, second) {
                case (.utf16(let first), .utf16(let second)):
                    return self[_utf16Range: first.lowerBound..<second.upperBound]
            }
        }
    }
}

