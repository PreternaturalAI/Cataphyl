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
    public func split(
        _ text: some PlainTextDocumentProtocol
    ) throws -> [PlainTextSplit] {
        try split(text: text.text)
    }
}

extension TextSplitter {
    @_spi(Internal)
    public func _naivelyMerge(
        _ splits: [PlainTextSplit],
        separator: String,
        topLevel: Bool 
    ) throws -> [PlainTextSplit] {
        let maximumSplitSize = configuration.maximumSplitSize ?? Int.maximum
        let maximumSplitOverlap = configuration.maximumSplitOverlap ?? 0
        let separatorLength = try configuration.tokenizer.tokenCount(for: separator)
        
        var result: [PlainTextSplit] = []
        var currentSplits: [PlainTextSplit] = []
        var currentTotal = 0
        
        for split in splits {
            let length = try configuration.tokenizer.tokenCount(for: split.text)
            
            func effectiveSeparatorLength() -> Int {
                separatorLength * (currentSplits.count > 1 ? 1 : 0)
            }
                        
            if (currentTotal + length + effectiveSeparatorLength()) > maximumSplitSize {
                if currentTotal > maximumSplitSize + 10 {
                    throw TextSplitterError.maximumSplitSizeExceeded(maximumSplitSize)
                }
                
                if currentSplits.count > 0 {
                    if let concatenated = _concatenate(currentSplits) {
                        result.append(concatenated)
                    }
                    
                    while currentTotal > maximumSplitOverlap || (currentTotal + length + effectiveSeparatorLength() > configuration.maximumSplitSize && currentTotal > 0) {
                        if !currentSplits.isEmpty {
                            currentTotal -= try configuration.tokenizer.tokenCount(for: currentSplits[0].text) + effectiveSeparatorLength()
                            
                            currentSplits.removeFirst()
                        } else {
                            break
                        }
                    }
                }
            }
            
            currentSplits.append(split)
            
            currentTotal += length + (separatorLength * (currentSplits.count > 1 ? 1: 0))
        }
        
        if let text = _concatenate(currentSplits, separator: separator) {
            result.append(text)
        }
        
        if topLevel {
            try validate(topLevel: result)
        }
        
        return result
    }
    
    func _concatenate(
        _ splits: [PlainTextSplit],
        separator: String? = nil
    ) -> PlainTextSplit? {
        let text: PlainTextSplit
        
        if let separator {
            text = splits
                .joined(separator: separator)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            text = splits
                .joined()
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if text.isEmpty {
            return nil
        } else {
            return text
        }
    }
    
    public func validate(
        topLevel splits: [PlainTextSplit]
    ) throws {
        guard let maximumSplitSize = configuration.maximumSplitSize else {
            return
        }
        
        if let biggerThanExpectedSplit = try splits.first(where: {
            try configuration.tokenizer.tokenCount(for: $0.text) > maximumSplitSize
        }) {
            let size = try configuration.tokenizer.tokenCount(for: biggerThanExpectedSplit.text)
            
            throw TextSplitterError.maximumSplitSizeExceeded(size)
        }

        let consecutives = Array(splits.consecutives().enumerated())
        let isSmallerThanExpected = try consecutives.contains { (index: Int, pair: (PlainTextSplit, PlainTextSplit)) -> Bool in
            let count = try configuration.tokenizer.tokenCount(for: (pair.0 + pair.1).text)
            
            if index == consecutives.lastIndex {
                return false
            }

            return count < maximumSplitSize
        }

        if isSmallerThanExpected {
            // throw TextSplitterError.topLevelSplitsMoreGranularThanExpected(splits)
        }
    }
}
