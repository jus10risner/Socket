//
//  EditCustomInfoView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct EditCustomInfoView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftCustomInfo = DraftCustomInfo()
    @ObservedObject var customInfo: CustomInfo
    
    init(customInfo: CustomInfo) {
        self.customInfo = customInfo
        
        _draftCustomInfo = StateObject(wrappedValue: DraftCustomInfo(customInfo: customInfo))
    }
    
    var body: some View {
        NavigationStack {
            DraftCustomInfoView(draftCustomInfo: draftCustomInfo, isEditView: true)
                .navigationTitle("Edit Info")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            customInfo.updateAndSave(draftCustomInfo: draftCustomInfo)
                            dismiss()
                        }
                        .disabled(draftCustomInfo.canBeSaved ? false : true)
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", role: .cancel) { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    EditCustomInfoView(customInfo: CustomInfo(context: DataController.preview.container.viewContext))
}
