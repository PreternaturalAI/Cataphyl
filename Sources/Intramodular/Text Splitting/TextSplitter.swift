//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Diagnostics
import FoundationX
import Swallow

/// Taken from https://github.com/MSUSAzureAccelerators/Knowledge-Mining-with-OpenAI.
public enum MSFT_KnowledgeMiningWithOpenAI {
    public static let SMALL_EMB_TOKEN_NUM  = 125
    public static let MEDIUM_EMB_TOKEN_NUM  = 250
    public static let LARGE_EMB_TOKEN_NUM  = 500
    public static let X_LARGE_EMB_TOKEN_NUM = 800
}

public enum TextSplitterError: Error {
    case invalidConfiguration
    case maximumSplitSizeExceeded(Int)
    case topLevelSplitsMoreGranularThanExpected([PlainTextSplit])
}

public struct TextSplitConfiguration: Codable, Hashable, Sendable {
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

/// A text splitter.
///
/// Expected to be deterministic.
public protocol TextSplitter: Logging {
    var configuration: TextSplitConfiguration { get }
    
    func split(text: String) throws -> [PlainTextSplit]
}

extension TextSplitter {
    public func _naivelyMerge(
        _ splits: [PlainTextSplit],
        separator: String
    ) throws -> [PlainTextSplit] {
        let maximumSplitSize = configuration.maximumSplitSize ?? Int.maximum
        let separatorLength = try configuration.tokenizer.tokenCount(for: separator)
        
        var chunks: [PlainTextSplit] = []
        var currentChunk: [PlainTextSplit] = []
        var currentTotal = 0
        
        for split in splits {
            let length = try configuration.tokenizer.tokenCount(for: split.text)
            
            if (currentTotal + length + (currentChunk.count > 0 ? separatorLength : 0)) > maximumSplitSize {
                if currentTotal > maximumSplitSize {
                    logger.warning(
                        TextSplitterError.maximumSplitSizeExceeded(maximumSplitSize)
                    )
                }
                
                if currentChunk.count > 0 {
                    if let chunk = join(chunks: currentChunk, separator: separator) {
                        if !chunk.text.contains(" ") {
                            print(chunk)
                        }
                        
                        chunks.append(chunk)
                    }
                    
                    while currentTotal > configuration.maxSplitOverlap || (currentTotal + length + (currentChunk.count > 0 ? separatorLength : 0) > configuration.maximumSplitSize && currentTotal > 0) {
                        if !currentChunk.isEmpty {
                            currentTotal -= try configuration.tokenizer.tokenCount(for: currentChunk[0].text) + (currentChunk.count > 0 ? separatorLength : 0)
                            
                            currentChunk.removeFirst()
                        } else {
                            break
                        }
                    }
                }
            }
            
            currentChunk.append(split)
            
            currentTotal += length + (separatorLength * (currentChunk.count > 1 ? 1 : 0))
        }
        
        if let text = join(chunks: currentChunk, separator: separator) {
            chunks.append(text)
        }
        
        return chunks
    }
    
    private func join(
        chunks: [PlainTextSplit],
        separator: String
    ) -> PlainTextSplit? {
        let text = chunks
            .joined(separator: separator)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if text.isEmpty {
            return nil
        } else {
            return text
        }
    }
    
    public func validate(
        topLevel splits: [PlainTextSplit]
    ) throws {
        let isSmallerThanExpected = try splits.consecutives().contains {
            if let maximumSplitSize = configuration.maximumSplitSize {
                return try configuration.tokenizer.tokenCount(for: ($0.0 + $0.1).text) < maximumSplitSize
            } else {
                return false
            }
        }
        
        if isSmallerThanExpected {
            throw TextSplitterError.topLevelSplitsMoreGranularThanExpected(splits)
        }
    }
}
