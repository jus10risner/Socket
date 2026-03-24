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
    
    @State private var copySymbol: CopySymbol = .tapToCopy
    @State private var showingEditCustomInfo = false
    
    var body: some View {
        List {
            if !customInfo.detail.isEmpty {
                Section(footer: Text("Tap to copy")) {
                    LabeledContent(customInfo.detail) {
                        Button {
                            let pasteBoard = UIPasteboard.general
                            pasteBoard.string = customInfo.detail
                            copySymbol = .copied
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copySymbol = .tapToCopy }
                        } label: {
                            Label("Copy to clipboard", systemImage: copySymbol.rawValue)
                                .labelStyle(.iconOnly)
                                .frame(width: 25, height: 25)
                                .contentTransition(.symbolEffect(.replace.downUp.wholeSymbol, options: .nonRepeating))
                        }
                    }
                }
            }
            
            FormFooterView(note: customInfo.note, photos: customInfo.sortedPhotosArray)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditCustomInfo) {
            AddEditCustomInfoView(customInfo: customInfo) {
                dismiss()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(customInfo.label)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            
            ToolbarItem {
                Button("Edit") {
                    showingEditCustomInfo = true
                }
                .adaptiveTint()
            }
        }
    }
    
    enum CopySymbol: String {
        case tapToCopy = "doc.on.doc", copied = "checkmark"
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let customInfo = CustomInfo(context: context)
    customInfo.label = "License Plate"
    customInfo.detail = "ABC 123"
    
    return CustomInfoDetailView(customInfo: customInfo)
}
