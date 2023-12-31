//
// Copyright (c) Vatsal Manot
//

import Swallow

extension PlainTextDocument {
    /// A sequential selection of text from a source `PlainTextDocument`.
    ///
    /// The selection maintains a list of consecutive ranges from the source document.
    public struct SequentialSelection: Codable, Comparable, Hashable, _ContiguousDocumentChunk {
        /// The consecutive ranges that constitute the span of the sequential selection of text.
        public struct Span: Comparable, Codable, Hashable, Sendable {
            public typealias RawValue = PlainTextDocument.ConsecutiveRanges
            
            public let rawValue: RawValue
            
            public init(rawValue: RawValue) {
                self.rawValue = rawValue
            }
            
            public static func < (lhs: Self, rhs: Self) -> Bool {
                lhs.rawValue.ranges.first! < rhs.rawValue.ranges.first!
            }
        }
        
        public let span: Span
        public let effectiveText: String
        
        public init(span: Span, effectiveText: String) {
            self.span = span
            self.effectiveText = effectiveText
        }
        
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.span < rhs.span
        }
    }
}

// MARK: - Identifiable

extension PlainTextDocument.SequentialSelection: CustomStringConvertible {
    public var description: String {
        text.description
    }
}

extension PlainTextDocument.SequentialSelection: CustomTextConvertible {
    public var text: String {
        effectiveText
    }
}

extension PlainTextDocument.SequentialSelection: Identifiable {
    public var id: Span {
        span
    }
}
