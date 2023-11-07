//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swift
import UniformTypeIdentifiers

public final class CataphylDocument: FileBundle {
    public init(_placeholder: _PlaceholderConfiguration) {
        
    }
}

extension UTType {
    public static let cataphyl = UTType("com.vmanot.cataphyl")
}
