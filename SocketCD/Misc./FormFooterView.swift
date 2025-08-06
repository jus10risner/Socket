//
//  FormFooterView.swift
//  SocketCD
//
//  Created by Justin Risner on 8/5/25.
//

import SwiftUI

struct FormFooterView: View {
    @Binding var note: String
    @Binding var photos: [Photo]
    private let deleteButtonTitle: String
    private let onDelete: (() -> Void)?
    
    init(note: Binding<String>, photos: Binding<[Photo]>, deleteButtonTitle: String, onDelete: (() -> Void)? = nil) {
        self._note = note
        self._photos = photos
        self.deleteButtonTitle = deleteButtonTitle
        self.onDelete = onDelete
    }
    
    var body: some View {
        Section("Note") {
            TextField("Optional", text: $note, axis: .vertical)
        }
        
        Section(header: AddPhotoButton(photos: $photos)) {
            PhotoGridView(photos: $photos)
        }
        
        if onDelete != nil {
            Button(deleteButtonTitle, role: .destructive) {
                onDelete?()
            }
        }
    }
    
}

#Preview {
    FormFooterView(note: .constant(""), photos: .constant([]), deleteButtonTitle: "Delete")
}
