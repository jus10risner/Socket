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
    let onDelete: (() -> Void)?
    
    init(note: Binding<String>, photos: Binding<[Photo]>, onDelete: (() -> Void)? = nil) {
        self._note = note
        self._photos = photos
        self.onDelete = onDelete
    }
    
    var body: some View {
        Section("Note") {
            TextField("Optional", text: $note, axis: .vertical)
        }
        
        Section(header: AddPhotoButton(photos: $photos)) {
            EditablePhotoGridView(photos: $photos)
        }
        
        if onDelete != nil {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        }
    }
    
}

#Preview {
    FormFooterView(note: .constant(""), photos: .constant([]))
}
