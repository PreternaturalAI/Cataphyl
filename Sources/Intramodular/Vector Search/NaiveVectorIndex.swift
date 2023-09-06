//
// Copyright (c) Vatsal Manot
//

import Accelerate
import Foundation
import Swallow

/// A naive vector index that uses an in-memory ordered dictionary to store vectors.
public final class NaiveVectorIndex<Key: Hashable>: VectorIndex {
    public var storage: OrderedDictionary<Key, [Double]> = []
    
    public init() {
        
    }
    
    @inline(__always)
    public func insert(
        contentsOf pairs: some Sequence<(Key, [Double])>
    ) {
        self.storage = OrderedDictionary(uniqueKeysWithValues: pairs.lazy.map({ ($0, $1) }))
    }
    
    @inline(__always)
    public func query(
        _ query: some VectorIndexQuery<Key>
    ) throws -> [VectorIndexSearchResult<NaiveVectorIndex>] {
        switch query {
            case let query as VectorIndexQueries.TopK<Key>:
                return rank(
                    query: query.vector,
                    topK: query.maximumNumberOfResults,
                    using: vDSP.cosineSimilarity
                )
            default:
                throw VectorIndexError.unsupportedQuery(query)
        }
    }
    
    @inline(__always)
    public func remove(_ items: Set<Key>) {
        for item in items {
            storage.removeValue(forKey: item)
        }
    }
    
    @inline(__always)
    private func rank(
        query: [Double],
        topK: Int,
        using metric: ([Double], [Double]) -> Double
    ) -> [VectorIndexSearchResult<NaiveVectorIndex>] {
        let similarities: [Double] = storage.map({ metric($0.value, query) })
        
        // Find the indices of top-k similarity values
        let sortedCollections = (0..<similarities.count).sorted(by: {
            similarities[$0] > similarities[$1]
        })
        let topIndices = Array(sortedCollections.prefix(topK))

        return topIndices.map {
            VectorIndexSearchResult(
                item: storage[$0].key,
                score: similarities[$0]
            )
        }
    }
}

// MARK: - Implemented Conformances

extension NaiveVectorIndex: Hashable {
    public func hash(into hasher: inout Hasher) {
        storage.hash(into: &hasher)
    }
    
    public static func == (lhs: NaiveVectorIndex, rhs: NaiveVectorIndex) -> Bool {
        lhs.storage == rhs.storage
    }
}

extension NaiveVectorIndex: Codable where Key: Codable {
    
}
