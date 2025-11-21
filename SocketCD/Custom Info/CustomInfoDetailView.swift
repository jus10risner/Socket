//
//  CustomInfoDetailView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct CustomInfoDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var customInfo: CustomInfo
    
    @State private var copySymbol: CopySymbol = .tapToCopy
    @State private var showingEditCustomInfo = false
    
    var body: some View {
        List {
            if !customInfo.detail.isEmpty {
                Section(footer: Text("Tap to copy")) {
                    LabeledContent(customInfo.detail) {
                        Button("Copy to clipboard", systemImage: copySymbol.rawValue) {
                            let pasteBoard = UIPasteboard.general
                            pasteBoard.string = customInfo.detail
                            copySymbol = .copied
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copySymbol = .tapToCopy }
                        }
                        .labelStyle(.iconOnly)
                        .frame(height: 20)
                        .contentTransition(.symbolEffect(.replace.downUp.wholeSymbol, options: .nonRepeating))
                    }
                }
            }
            
            FormFooterView(note: customInfo.note, photos: customInfo.sortedPhotosArray)
        }
        .navigationTitle(customInfo.label)
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
    
    enum CopySymbol: String {
        case tapToCopy = "document.on.document", copied = "checkmark"
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let customInfo = CustomInfo(context: context)
    customInfo.label = "License Plate"
    customInfo.detail = "ABC 123"
    
    return CustomInfoDetailView(customInfo: customInfo)
        .environmentObject(AppSettings())
}
