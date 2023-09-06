//
// Copyright (c) Vatsal Manot
//

import Accelerate
import Foundation
import Swallow

/// A type that represents a vector query.
///
/// This is a protocol (instead of say, an enum) in order to future-proof for complex query types that can't be anticipated at the moment.
public protocol VectorIndexQuery<Item> {
    associatedtype Item
}

// MARK: - Implemented Conformances

public enum VectorIndexQueries {
    public struct TopK<Item>: VectorIndexQuery {
        public let vector: [Double]
        public let maximumNumberOfResults: Int
        
        public init(vector: [Double], maximumNumberOfResults: Int) {
            self.vector = vector
            self.maximumNumberOfResults = maximumNumberOfResults
        }
    }
}

extension VectorIndexQuery {
    public static func topMatches<T>(
        for vector: [Double],
        maximumNumberOfResults: Int
    ) -> Self where Self == VectorIndexQueries.TopK<T> {
        .init(vector: vector, maximumNumberOfResults: maximumNumberOfResults)
    }
}
