//
//  FormFooterView.swift
//  SocketCD
//
//  Created by Justin Risner on 8/5/25.
//

import SwiftUI

struct FormFooterView: View {
    private let note: Binding<String>
    private let photos: Binding<[Photo]>
    private let documents: Binding<[AttachedDocument]>
    private let isEditable: Bool
    private let deleteButtonTitle: String?
    private let onDelete: (() -> Void)?

    // MARK: - Editable initializer
    init(
        note: Binding<String>,
        photos: Binding<[Photo]>,
        documents: Binding<[AttachedDocument]>,
        deleteButtonTitle: String,
        onDelete: (() -> Void)? = nil
    ) {
        self.note = note
        self.photos = photos
        self.documents = documents
        self.isEditable = true
        self.deleteButtonTitle = deleteButtonTitle
        self.onDelete = onDelete
    }

    // MARK: - Read-only initializer
    init(note: String, photos: [Photo], documents: [AttachedDocument]) {
        self.note = .constant(note)
        self.photos = .constant(photos)
        self.documents = .constant(documents)
        self.isEditable = false
        self.deleteButtonTitle = nil
        self.onDelete = nil
    }

    private var hasAttachments: Bool {
        !photos.wrappedValue.isEmpty || !documents.wrappedValue.isEmpty
    }

    var body: some View {
        Group {
            if isEditable {
                EditableNoteSection(note: note)
                
                EditableAttachmentsSection(
                    photos: photos,
                    documents: documents
                )
            } else if !note.wrappedValue.isEmpty || hasAttachments {
                if !note.wrappedValue.isEmpty {
                    ReadOnlyNoteSection(note: note.wrappedValue)
                }

                if hasAttachments {
                    AttachmentsView(
                        photos: photos,
                        documents: documents
                    )
                }
            }

            if let deleteButtonTitle, let onDelete {
                Section {
                    Button(deleteButtonTitle, role: .destructive, action: onDelete)
                }
            }
        }
    }
}

private struct EditableNoteSection: View {
    @Binding var note: String

    var body: some View {
        Section {
            TextField("Note", text: $note, axis: .vertical)
        }
    }
}

private struct ReadOnlyNoteSection: View {
    let note: String

    var body: some View {
        Section {
            LabeledContent("Note") {
                Text(note)
                    .textSelection(.enabled)
            }
        }
    }
}

private struct EditableAttachmentsSection: View {
    @Binding var photos: [Photo]
    @Binding var documents: [AttachedDocument]

    var body: some View {
        Section {
            AddAttachmentButton(photos: $photos, documents: $documents)

            if !documents.isEmpty {
                DocumentListView(documents: $documents, isEditable: true)
            }
            
            if !photos.isEmpty {
                EditablePhotoSection(photos: $photos)
            }
        }
    }
}

private struct EditablePhotoSection: View {
    @Binding var photos: [Photo]

    var body: some View {
        Section {
            FormPhotosView(photos: $photos, isEditable: true)
        }
    }
}

private struct AttachmentsView: View {
    @Binding var photos: [Photo]
    @Binding var documents: [AttachedDocument]

    @State private var selectedCategory = AttachmentCategory.photos

    private var hasPhotosAndDocuments: Bool {
        !photos.isEmpty && !documents.isEmpty
    }

    var body: some View {
        readOnlyAttachments
            .onChange(of: photos.count) {
                if photos.isEmpty {
                    selectedCategory = .documents
                } else if !documents.isEmpty {
                    selectedCategory = .photos
                }
            }
            .onChange(of: documents.count) {
                if documents.isEmpty {
                    selectedCategory = .photos
                } else if !photos.isEmpty {
                    selectedCategory = .documents
                }
            }
    }

    @ViewBuilder
    private var readOnlyAttachments: some View {
        if hasPhotosAndDocuments {
            Section {
                Picker("Attachment Type", selection: $selectedCategory) {
                    Text("Photos")
                        .tag(AttachmentCategory.photos)

                    Text("Documents")
                        .tag(AttachmentCategory.documents)
                }
                .pickerStyle(.segmented)
//                .labelsHidden()
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if selectedCategory == .photos {
                photoSection
                    .listSectionSpacing(3)
            } else {
                documentSection
                    .listSectionSpacing(3)
            }
        } else {
            singleAttachmentSection
        }
    }

    @ViewBuilder
    private var singleAttachmentSection: some View {
        Section {
            singleAttachmentContent
        }
    }

    @ViewBuilder
    private var singleAttachmentContent: some View {
        if !photos.isEmpty {
            FormPhotosView(photos: $photos, isEditable: false)
        } else {
            documentList
        }
    }

    private var photoSection: some View {
        Section {
            FormPhotosView(photos: $photos, isEditable: false)
        }
    }

    private var documentSection: some View {
        Section {
            documentList
        }
    }

    private var documentList: some View {
        DocumentListView(
            documents: $documents,
            isEditable: false
        )
    }
}

private enum AttachmentCategory {
    case photos
    case documents
}

#Preview {
    FormFooterView(
        note: .constant(""),
        photos: .constant([]),
        documents: .constant([]),
        deleteButtonTitle: "Delete"
    )
}
