//
//  FormFooterView.swift
//  SocketCD
//
//  Created by Justin Risner on 8/5/25.
//

import SwiftUI

struct FormFooterView: View {
    private let noteBinding: Binding<String>?
    private let noteValue: String
    
    private let photosBinding: Binding<[Photo]>?
    private let photosValue: [Photo]
    
    private let deleteButtonTitle: String?
    private let onDelete: (() -> Void)?
    
    // MARK: - Editable initializer
    init(note: Binding<String>, photos: Binding<[Photo]>, deleteButtonTitle: String, onDelete: (() -> Void)? = nil) {
        self.noteBinding = note
        self.noteValue = note.wrappedValue
        self.photosBinding = photos
        self.photosValue = photos.wrappedValue
        self.deleteButtonTitle = deleteButtonTitle
        self.onDelete = onDelete
    }

    // MARK: - Read-only initializer
    init(note: String, photos: [Photo]) {
        self.noteBinding = nil
        self.noteValue = note
        self.photosBinding = nil
        self.photosValue = photos
        self.deleteButtonTitle = nil
        self.onDelete = nil
    }
    
    var body: some View {
        if let noteBinding {
            TextField("Note", text: noteBinding, axis: .vertical)
        } else if noteValue != "" {
            LabeledContent("Note", value: noteValue)
        }

        if let photosBinding {
            // Add/Edit View: always show section
            Section(header: AddPhotoButton(photos: photosBinding)) {
                PhotoGridView(photos: photosBinding)
            }
        } else if !photosValue.isEmpty {
            // DetailView: only show section if photos exist
            Section {
                PhotoGridView(photos: photosValue)
            }
        }

        if let deleteButtonTitle, let onDelete {
            Button(deleteButtonTitle, role: .destructive, action: onDelete)
        }
    }
    
}

#Preview {
    FormFooterView(note: .constant(""), photos: .constant([]), deleteButtonTitle: "Delete")
}
