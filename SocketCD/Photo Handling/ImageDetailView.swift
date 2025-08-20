//
//  ImageDetailView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct ImageDetailView: View {
    @Environment(\.dismiss) var dismiss
    let image: UIImage
    
    @State private var imageURL: URL?
    
    var body: some View {
        NavigationStack {
            ZStack {
                ImageViewer(image: Image(uiImage: image))
                
                VStack {
                    Color.clear
                        .background(.thickMaterial, in: Rectangle())
                        .edgesIgnoringSafeArea(.top)
                        .frame(maxWidth: .infinity, maxHeight: .zero)
                    
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if let imageURL {
                        ShareLink("Share Image", item: imageURL)
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .accessibilityLabel("Dismiss")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await createImageURL()
        }
    }
    
    // MARK: - Methods
    
    // Creates a URL for the selected image, for sharing
    func createImageURL() async {
        let formatter = DateFormatter()
        let fileName = "image-\(formatter.string(from: Date())).jpg"
        let tempDirectory = NSTemporaryDirectory()
        let fileURL = URL(fileURLWithPath: tempDirectory, isDirectory: true).appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("unable to compress image")
            return
        }
        
        do {
            try imageData.write(to: fileURL)
            imageURL = fileURL
        } catch {
            print("Failed to create file: \(error)")
        }
    }
}

#Preview {
    ImageDetailView(image: UIImage(imageLiteralResourceName: "example"))
}
