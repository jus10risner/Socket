//
//  AttachedDocument+helper.swift
//  SocketCD
//

import CoreData
import Foundation
import UniformTypeIdentifiers

extension AttachedDocument {
    var timeStamp: Date {
        get { timeStamp_ ?? Date() }
        set { timeStamp_ = newValue }
    }

    var documentData: Data {
        get { data_ ?? Data() }
        set { data_ = newValue }
    }

    var fileName: String {
        get { fileName_ ?? "Document.pdf" }
        set { fileName_ = newValue }
    }

    var contentType: UTType {
        get { contentType_.flatMap(UTType.init) ?? .data }
        set { contentType_ = newValue.identifier }
    }

    var isPDF: Bool {
        contentType.conforms(to: .pdf)
    }

    static func create(from url: URL, in context: NSManagedObjectContext) throws -> AttachedDocument {
        guard url.startAccessingSecurityScopedResource() else {
            throw CocoaError(.fileReadNoPermission)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        guard !data.isEmpty else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let document = AttachedDocument(context: context)
        document.id = UUID()
        document.timeStamp = .now
        document.documentData = data
        document.fileName = url.lastPathComponent
        document.contentType = .pdf
        return document
    }
}
