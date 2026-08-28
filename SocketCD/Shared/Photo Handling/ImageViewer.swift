//
//  ImageViewer.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct ImageViewer: View {
    private static let maximumScale: CGFloat = 5
    private static let doubleTapScale: CGFloat = 2.5

    let image: UIImage
    @Binding var isZoomed: Bool

    @State private var scale: CGFloat = 1
    @State private var startingScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var startingOffset: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .simultaneousGesture(magnificationGesture(in: proxy.size))
                .simultaneousGesture(
                    panGesture(in: proxy.size),
                    isEnabled: isZoomed
                )
                .onTapGesture(count: 2) {
                    toggleZoom(in: proxy.size)
                }
                .onChange(of: isZoomed) { _, isZoomed in
                    if !isZoomed {
                        resetZoom()
                    }
                }
                .onChange(of: proxy.size) { _, size in
                    setOffset(clampedOffset(offset, at: scale, in: size))
                }
        }
    }

    private func magnificationGesture(in size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(startingScale * value.magnification, 1), Self.maximumScale)
                isZoomed = scale > 1
            }
            .onEnded { _ in
                startingScale = scale
                setOffset(clampedOffset(offset, at: scale, in: size))
            }
    }

    private func panGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: startingOffset.width + value.translation.width,
                    height: startingOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                withAnimation(.snappy) {
                    setOffset(clampedOffset(offset, at: scale, in: size))
                }
            }
    }

    private func toggleZoom(in size: CGSize) {
        withAnimation(.snappy) {
            if isZoomed {
                resetZoom()
            } else {
                scale = Self.doubleTapScale
                startingScale = scale
                setOffset(clampedOffset(.zero, at: scale, in: size))
                isZoomed = true
            }
        }
    }

    private func resetZoom() {
        scale = 1
        startingScale = 1
        setOffset(.zero)
        isZoomed = false
    }

    private func setOffset(_ newOffset: CGSize) {
        offset = newOffset
        startingOffset = newOffset
    }

    private func clampedOffset(_ proposedOffset: CGSize, at scale: CGFloat, in containerSize: CGSize) -> CGSize {
        let fittedSize = fittedImageSize(in: containerSize)
        let maximumX = max(0, (fittedSize.width * scale - containerSize.width) / 2)
        let maximumY = max(0, (fittedSize.height * scale - containerSize.height) / 2)

        return CGSize(
            width: min(max(proposedOffset.width, -maximumX), maximumX),
            height: min(max(proposedOffset.height, -maximumY), maximumY)
        )
    }

    private func fittedImageSize(in containerSize: CGSize) -> CGSize {
        guard image.size.width > 0, image.size.height > 0 else { return .zero }

        let fittingScale = min(
            containerSize.width / image.size.width,
            containerSize.height / image.size.height
        )
        return CGSize(
            width: image.size.width * fittingScale,
            height: image.size.height * fittingScale
        )
    }
}

#Preview {
    ImageViewer(
        image: UIImage(imageLiteralResourceName: "example"),
        isZoomed: .constant(false)
    )
}
