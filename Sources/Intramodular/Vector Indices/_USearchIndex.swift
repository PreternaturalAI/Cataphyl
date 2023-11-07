//
// Copyright (c) Vatsal Manot
//

import Accelerate
import Foundation
import Swallow
import USearch

public struct _USearchIndex {
    public struct Configuration: Codable, Hashable, Sendable {
        public var index: USearchMetric
    }
}

extension USearchMetric: Codable {
    public init(from decoder: Decoder) throws {
        self = try Self(rawValue: try RawValue(from: decoder)).unwrap()
    }
    
    public func encode(to encoder: Encoder) throws {
        try rawValue.encode(to: encoder)
    }
}
