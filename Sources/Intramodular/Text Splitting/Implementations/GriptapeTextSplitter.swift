//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public protocol GriptapeTextSplitter: TextSplitter {
    var separators: [GriptapeChunkSeparator] { get }
}

extension GriptapeTextSplitter {
    public var separators: [GriptapeChunkSeparator] {
        [GriptapeChunkSeparator(" ")]
    }
    
    public func split(text: String) throws -> [PlainTextSplit] {
        try chunkRecursively(chunk: PlainTextSplit(source: text), currentSeparator: nil)
    }
    
    public func chunkRecursively(
        chunk: PlainTextSplit,
        currentSeparator: GriptapeChunkSeparator? = nil
    ) throws -> [PlainTextSplit] {
        let maximumSplitSize = configuration.maximumSplitSize
        let tokenCount = try configuration.tokenizer.tokenCount(for: chunk.text)
        
        if tokenCount <= maximumSplitSize {
            return [chunk]
        } else {
            var balanceIndex = -1
            var balanceDiff = Double.infinity
            var tokensCount = 0
            let halfTokenCount = tokenCount / 2
            
            let separators: [GriptapeChunkSeparator]
            
            if let currentSeparator {
                separators = Array(self.separators[try self.separators.firstIndex(of: currentSeparator).unwrap()...])
            } else {
                separators = self.separators
            }
            
            for separator in separators {
                let subchunks = chunk.components(separatedBy: separator.value).filter {
                    !$0.isEmpty
                }
                
                if !subchunks.isEmpty {
                    for (index, subchunk) in subchunks.enumerated() {
                        var subchunk = subchunk
                        if index < subchunks.count {
                            if separator.isPrefix {
                                subchunk = separator.value + subchunk
                            } else {
                                subchunk = subchunk + separator.value
                            }
                        }
                        
                        tokensCount += try configuration.tokenizer.tokenCount(for: subchunk.text)
                        
                        if Double(abs(tokensCount - halfTokenCount)) < balanceDiff {
                            balanceIndex = index
                            balanceDiff = abs(Double(tokensCount) - Double(halfTokenCount))
                        }
                    }
                    
                    var firstSubchunk: PlainTextSplit
                    var secondSubchunk: PlainTextSplit
                    
                    if separator.isPrefix {
                        firstSubchunk = PlainTextSplit(stringLiteral: separator.value) + subchunks[..<(balanceIndex + 1)].joined(separator: separator.value)
                        secondSubchunk = separator.value + subchunks[(balanceIndex + 1)...].joined(separator: separator.value)
                    } else {
                        firstSubchunk = subchunks[..<(balanceIndex + 1)].joined(separator: separator.value) + separator.value
                        secondSubchunk = subchunks[(balanceIndex + 1)...].joined(separator: separator.value)
                    }
                    
                    let firstSubchunkRec = try chunkRecursively(chunk: firstSubchunk.trimmingCharacters(in: .whitespaces), currentSeparator: separator)
                    let secondSubchunkRec = try chunkRecursively(chunk: secondSubchunk.trimmingCharacters(in: .whitespaces), currentSeparator: separator)
                    
                    if !firstSubchunkRec.isEmpty && !secondSubchunkRec.isEmpty {
                        return firstSubchunkRec + secondSubchunkRec
                    } else if !firstSubchunkRec.isEmpty {
                        return firstSubchunkRec
                    } else if !secondSubchunkRec.isEmpty {
                        return secondSubchunkRec
                    } else {
                        return []
                    }
                }
            }
            
            return []
        }
    }
}

// MARK: - Auxiliary

public struct GriptapeChunkSeparator: Hashable {
    public let value: String
    public let isPrefix: Bool
    
    public init(_ value: String, isPrefix: Bool = false) {
        self.value = value
        self.isPrefix = isPrefix
    }
}

