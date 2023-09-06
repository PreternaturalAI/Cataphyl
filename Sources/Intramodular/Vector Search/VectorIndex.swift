//
// Copyright (c) Vatsal Manot
//

import Accelerate
import Foundation
import Swallow

public protocol AsyncVectorIndex<Key> {
    associatedtype Key: Hashable
    
    mutating func insert(
        contentsOf pairs: some Sequence<(Key, [Double])>
    ) async throws
    
    mutating func remove(
        _ items: Set<Key>
    ) throws
    
    func query<Query: VectorIndexQuery<Key>>(
        _ query: Query
    ) async throws -> [VectorIndexSearchResult<Self>]
}

public protocol VectorIndex<Key>: AsyncVectorIndex {
    mutating func insert(contentsOf pairs: some Sequence<(Key, [Double])>) throws
    mutating func remove(_ items: Set<Key>) throws
    
    func query<Query: VectorIndexQuery<Key>>(
        _ query: Query
    ) throws -> [VectorIndexSearchResult<Self>]
}

// MARK: - Auxiliary

public struct VectorIndexSearchResult<Index: AsyncVectorIndex> {
    public let item: Index.Key
    public let score: Double
}

public enum VectorIndexError: Error {
    case unsupportedQuery(any VectorIndexQuery)
}
