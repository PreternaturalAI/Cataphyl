//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import FoundationX
import Swallow

public struct RecursiveCharacterTextSplitter: Codable, TextSplitter {
    public let configuration: TextSplitterConfiguration
    public let separators: [String]
    
    public init(
        configuration: TextSplitterConfiguration,
        separators: [String] = ["\n\n", "\n", " "]
    ) {
        self.configuration = configuration
        self.separators = separators
    }
}

// MARK: - Implementation

extension RecursiveCharacterTextSplitter {
    public func split(
        text: String
    ) throws -> [PlainTextSplit] {
        try _split(PlainTextSplit(source: text), topLevel: true)
    }
    
    private func _split(
        _ input: PlainTextSplit,
        topLevel: Bool
    ) throws -> [PlainTextSplit] {
        let maximumSplitSize = configuration.maximumSplitSize ?? Int.maximum
        let separator = try _bestSeparator(for: input)
        let splits = input
            .components(separatedBy: separator)
            .compactMap({ $0.trimmingCharacters(in: .whitespaces) })
            .filter({ !$0.isEmpty })
        
        if try configuration.tokenizer.tokenCount(for: input.text) < maximumSplitSize {
            return [input]
        }
        
        var result: [PlainTextSplit] = []
        var validSplits: [PlainTextSplit] = []
        
        for split in splits {
            if try configuration.tokenizer.tokenCount(for: split.text) < maximumSplitSize {
                validSplits.append(split)
            } else {
                if !validSplits.isEmpty {
                    let merged = try _naivelyMerge(
                        validSplits,
                        separator: separator
                    )
                    
                    try validate(topLevel: merged)
                    
                    result.append(contentsOf: merged)
                    
                    validSplits.removeAll()
                }
                
                let otherInfo = try self._split(split, topLevel: false)
                
                result.append(contentsOf: otherInfo)
            }
        }
        
        if !validSplits.isEmpty {
            let merged = try _naivelyMerge(
                validSplits,
                separator: separator
            )
            
            try validate(topLevel: merged)
            
            result.append(contentsOf: merged)
            
            validSplits.removeAll()
        }
        
        try _tryAssert(validSplits.isEmpty)
        
        if topLevel {
            return result
        } else {
            return result
        }
    }
    
    private func _bestSeparator(
        for split: PlainTextSplit
    ) throws -> String {
        var result = try separators.last.unwrap()
        
        for currentSeparator in separators {
            if currentSeparator.isEmpty {
                result = ""
                
                break
            }
            
            if split.contains(currentSeparator) {
                result = currentSeparator
                
                break
            }
        }
        
        return result
    }
}
