//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct PlainTextDocumentChunk: Codable, CustomTextConvertible, Hashable, _ContiguousDocumentChunk {
    public typealias ID = Span
    
    public struct Span: Codable, Hashable, Sendable {
        public typealias RawValue = PlainTextDocument.ConsecutiveRanges
        
        public let rawValue: RawValue
        
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
    }
    
    public let text: String
    public let span: Span
    
    public init(text: String, span: Span) {
        self.text = text
        self.span = span
    }
}

// MARK: - Identifiable

extension PlainTextDocumentChunk: CustomStringConvertible {
    public var description: String {
        text.description
    }
}

extension PlainTextDocumentChunk: Identifiable {
    public var id: ID {
        span
    }
}
