//
//  DraftCustomInfoView.swift
//  SocketCD
//
//  Created by Justin Risner on 4/5/24.
//

import SwiftUI

struct DraftCustomInfoView: View {
    @ObservedObject var draftCustomInfo: DraftCustomInfo
    let isEditView: Bool
    
    @FocusState var isInputActive: Bool
    @FocusState var fieldInFocus: Bool
    
    var body: some View {
        Form {
            Section {
                TextField("Label (e.g. License Plate)", text: $draftCustomInfo.label)
                    .focused($fieldInFocus)
                    .onAppear {
                        if isEditView == false {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                fieldInFocus = true
                            }
                        }
                    }
                
                TextField("Detail (e.g. ABC 123)", text: $draftCustomInfo.detail)
            }
            .focused($isInputActive)
            
            Section("Note") {
                TextEditor(text: $draftCustomInfo.note)
                    .frame(minHeight: 50)
                    .focused($isInputActive)
            }
            
            Section(header: AddPhotoButton(photos: $draftCustomInfo.photos)) {
                EditablePhotoGridView(photos: $draftCustomInfo.photos)
            }
        }
        .modifier(SwipeToDismissKeyboard())
    }
}

#Preview {
    DraftCustomInfoView(draftCustomInfo: DraftCustomInfo(), isEditView: true)
}
