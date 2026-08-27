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

    private var hasPhotosAndDocuments: Bool {
        !photos.wrappedValue.isEmpty && !documents.wrappedValue.isEmpty
    }

    private var editableDetailsSection: some View {
        Section("Details") {
            HStack(alignment: .top) {
                Image(systemName: "text.justify.leading")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                
                TextField("Note", text: note, axis: .vertical)
            }

            if !hasAttachments {
                AddAttachmentButton(photos: photos, documents: documents)
            }
        }
    }

    var body: some View {
        if isEditable {
            if hasAttachments {
                editableDetailsSection
                    .listSectionSpacing(8)
            } else {
                editableDetailsSection
            }

            if hasAttachments {
                AttachmentsView(
                    photos: photos,
                    documents: documents,
                    isEditable: true,
                    showsDetailsHeader: false
                )
            }
        } else if !note.wrappedValue.isEmpty || hasAttachments {
            if !note.wrappedValue.isEmpty {
                Section("Details") {
                    Text(note.wrappedValue)
                        .textSelection(.enabled)
                }
            }

            if hasAttachments {
                if note.wrappedValue.isEmpty {
                    AttachmentsView(
                        photos: photos,
                        documents: documents,
                        isEditable: false,
                        showsDetailsHeader: !hasPhotosAndDocuments
                    )
                } else {
                    AttachmentsView(
                        photos: photos,
                        documents: documents,
                        isEditable: false,
                        showsDetailsHeader: false
                    )
                    .listSectionSpacing(8)
                }
            }
        }

        if let deleteButtonTitle, let onDelete {
            Section {
                Button(deleteButtonTitle, role: .destructive, action: onDelete)
            }
            .listSectionSpacing(.default)
        }
    }
}

private struct AttachmentsView: View {
    @Binding var photos: [Photo]
    @Binding var documents: [AttachedDocument]
    let isEditable: Bool
    let showsDetailsHeader: Bool

    @State private var selectedCategory = AttachmentCategory.photos

    private var hasPhotosAndDocuments: Bool {
        !photos.isEmpty && !documents.isEmpty
    }

    var body: some View {
        Group {
            if isEditable {
                editableAttachments
            } else {
                readOnlyAttachments
            }
        }
        .onChange(of: photos.count) {
            guard !isEditable else { return }

            if photos.isEmpty {
                selectedCategory = .documents
            } else if !documents.isEmpty {
                selectedCategory = .photos
            }
        }
        .onChange(of: documents.count) {
            guard !isEditable else { return }

            if documents.isEmpty {
                selectedCategory = .photos
            } else if !photos.isEmpty {
                selectedCategory = .documents
            }
        }
    }

    @ViewBuilder
    private var editableAttachments: some View {
        if photos.isEmpty {
            primaryAttachmentSection
        } else {
            primaryAttachmentSection
                .listSectionSpacing(8)

            photoSection
        }
    }

    private var primaryAttachmentSection: some View {
        Section {
            AddAttachmentButton(photos: $photos, documents: $documents)

            if !documents.isEmpty {
                documentList
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
        if showsDetailsHeader {
            Section("Details") {
                singleAttachmentContent
            }
        } else {
            Section {
                singleAttachmentContent
            }
        }
    }

    @ViewBuilder
    private var singleAttachmentContent: some View {
        if !photos.isEmpty {
            PhotoGridView(photos: $photos, isEditable: isEditable)
        } else {
            documentList
        }
    }

    private var photoSection: some View {
        Section {
            PhotoGridView(photos: $photos, isEditable: isEditable)
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
            isEditable: isEditable
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
