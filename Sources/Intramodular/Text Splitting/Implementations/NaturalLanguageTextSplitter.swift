//
// Copyright (c) Vatsal Manot
//

import NaturalLanguage
import Swallow

public struct NaturalLanguageTextSplitter: TextSplitter {
    public var configuration: TextSplitConfiguration
    
    public init(configuration: TextSplitConfiguration) {
        self.configuration = configuration
    }
    
    public func split(
        text: String
    ) throws -> [PlainTextSplit] {
        let maximumSplitSize = configuration.maximumSplitSize ?? Int.maximum
        let sentences = segmentTextIntoSentences(text: text)
        var chunks: [PlainTextSplit] = []
        var currentChunk = PlainTextSplit()
        var currentSplitSize = 0
        
        for sentence in sentences {
            let currentPlusSentenceSplitSize = try currentSplitSize + configuration.tokenizer.tokenCount(for: sentence.text)
            
            if currentPlusSentenceSplitSize < maximumSplitSize {
                currentChunk.append(sentence)
                
                currentSplitSize += try configuration.tokenizer.tokenCount(for: sentence.text)
            } else {
                chunks.append(currentChunk)
                
                currentChunk = sentence
                currentSplitSize = sentence.count
            }
        }
        
        return chunks
    }
    
    private func segmentTextIntoSentences(
        text: String
    ) -> [PlainTextSplit] {
        NLTokenizer.tokens(for: text, unit: .sentence).map {
            PlainTextSplit($0, in: text)
        }
    }
}

extension String {
    fileprivate func plainText() -> String {
        self.removingCharacters(in: "\"`()%$#@[]{}<>")
            .replacingOccurrences(of: "\n", with: " ")
    }
}
