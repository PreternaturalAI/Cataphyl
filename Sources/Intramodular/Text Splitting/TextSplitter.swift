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
        self.maxSplitOverlap = maxSplitOverlap
        self.tokenizer = tokenizer
        
        if let maximumSplitSize {
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
        
        // Iterate through the provided text splits.
        for split in splits {
            // Check if adding the current split to the total length along with the separator would exceed the desired chunk size
            let length = try configuration.tokenizer.tokenCount(for: split.text)
            
            if (currentTotal + length + (currentChunk.count > 0 ? separatorLength : 0)) > maximumSplitSize {
                if currentTotal > maximumSplitSize {
                    logger.warning(
                        TextSplitterError.maximumSplitSizeExceeded(maximumSplitSize)
                    )
                }
                
                if currentChunk.count > 0 {
                    // If the current document has content, append the joined document to the final list of documents.
                    if let chunk = join(chunks: currentChunk, separator: separator) {
                        if !chunk.text.contains(" ") {
                            print(chunk)
                        }
                        chunks.append(chunk)
                    }
                    
                    // Continue removing the first element of the current document until it doesn't exceed the specified chunk overlap or chunk size
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
            
            // Add the current split to the current document and update the total length.
            currentChunk.append(split)
            
            currentTotal += length + (separatorLength * (currentChunk.count > 1 ? 1 : 0))
        }
        
        // After iterating through all splits, join any remaining elements in the current document and add it to the final list of documents
        if let doc = join(chunks: currentChunk, separator: separator) {
            chunks.append(doc)
        }
        
        return chunks
    }
    
    /// This function takes an array of strings (`chunks`) and a separator as input, joins the strings using the separator, and trims whitespace from the beginning and end of the resulting string. If the resulting string is empty, the function returns `nil`, otherwise it returns the joined and trimmed string
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
