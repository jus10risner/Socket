//
//  CustomInfoDetailView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct CustomInfoDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var customInfo: CustomInfo
    
    @State private var copyHint = "Tap to copy"
    @State private var showingEditCustomInfo = false
    
    var body: some View {
        List {
            if !customInfo.detail.isEmpty {
                Section(footer: Text(copyHint)) {
                    LabeledContent(customInfo.detail) {
                        Button("Copy to clipboard", systemImage: "document.on.document") {
                            let pasteBoard = UIPasteboard.general
                            pasteBoard.string = customInfo.detail
                            copyHint = "Copied!"
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copyHint = "Tap to copy" }
                        }
                        .labelStyle(.iconOnly)
                    }
                }
                .textCase(nil)
            }
            
            FormFooterView(note: customInfo.note, photos: customInfo.sortedPhotosArray)
        }
        .navigationTitle(customInfo.label)
//        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditCustomInfo) {
            AddEditCustomInfoView(customInfo: customInfo) {
                dismiss()
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Edit") {
                    showingEditCustomInfo = true
                }
                .adaptiveTint()
            }
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let customInfo = CustomInfo(context: context)
    customInfo.label = "License Plate"
    customInfo.detail = "ABC 123"
    
    return CustomInfoDetailView(customInfo: customInfo)
}
