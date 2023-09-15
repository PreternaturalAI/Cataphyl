//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Diagnostics
import FoundationX
import Swallow

/// A text splitter.
///
/// Expected to be deterministic.
public protocol TextSplitter: Logging {
    var configuration: TextSplitterConfiguration { get }
    
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
