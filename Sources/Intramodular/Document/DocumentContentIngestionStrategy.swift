//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

public protocol DocumentContentIngestionStrategy: Codable, HadeanIdentifiable, Hashable {
    associatedtype Document
    associatedtype Ingestion: PlainTextDocumentProtocol
    
    func ingest(
        _ document: Document
    ) async throws -> Ingestion
}

// MARK: - Implementation

extension DocumentContentIngestionStrategy {
    public var _opaque_Ingestion: any PlainTextDocumentProtocol.Type {
        Ingestion.self
    }
    
    public func _opaque_ingest(
        _ document: _AnyReferenceFileDocument
    ) async throws -> any PlainTextDocumentProtocol {
        let document = try await document.cast(to: Document.self)
        let ingestion = try await ingest(document)
        
        return ingestion
    }
}

// MARK: - Extensions

extension DocumentContentIngestionStrategy {
    public func ingest<D, S: AllCaseInitiable>(
        _ document: D
    ) async throws -> Ingestion where Document == _ContentSelectionSpecified<D, S> {
        try await self.ingest(_ContentSelectionSpecified(base: document))
    }
}
