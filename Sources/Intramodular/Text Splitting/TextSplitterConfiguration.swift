//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Diagnostics
import FoundationX
import Swallow

public enum TextSplitterError: Error {
    case invalidConfiguration
    case maximumSplitSizeExceeded(Int)
    case topLevelSplitsMoreGranularThanExpected([PlainTextSplit])
}

public struct TextSplitterConfiguration: Codable, Hashable, Sendable {
    public let maximumSplitSize: Int?
    public let maxSplitOverlap: Int?
    @_UnsafelySerialized
    public var tokenizer: any Codable & TextTokenizer
    
    public init(
        maximumSplitSize: Int?,
        maxSplitOverlap: Int?,
        tokenizer: any Codable & TextTokenizer = _StringCharacterTokenizer()
    ) throws {
        self.maximumSplitSize = maximumSplitSize
        self.maxSplitOverlap = maxSplitOverlap ?? 0
        self.tokenizer = tokenizer
        
        if let maximumSplitSize, let maxSplitOverlap {
            guard maximumSplitSize > maxSplitOverlap else {
                assertionFailure(TextSplitterError.invalidConfiguration)
                
                return
            }
        }
    }
}
