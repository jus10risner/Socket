import SwiftUI

extension View {
    func keyboardToolbar(
        isFocused: Bool,
        canMovePrevious: Bool,
        canMoveNext: Bool,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) -> some View {
        modifier(KeyboardToolbarModifier(
            isFocused: isFocused,
            toolbar: KeyboardToolbar(
                canMovePrevious: canMovePrevious,
                canMoveNext: canMoveNext,
                onPrevious: onPrevious,
                onNext: onNext,
                onDone: onDone
            )
        ))
    }
}

private struct KeyboardToolbarModifier: ViewModifier {
    let isFocused: Bool
    let toolbar: KeyboardToolbar

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            content
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        toolbar.compactToolbar
                    }
                    .sharedBackgroundVisibility(.hidden)
                }
        } else if #available(iOS 26.0, *) {
            content
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    toolbar
                        .opacity(isFocused ? 1 : 0)
                        .offset(y: isFocused ? 0 : 100)
                        .frame(height: isFocused ? nil : 0, alignment: .top)
                        .allowsHitTesting(isFocused)
                        .accessibilityHidden(!isFocused)
                        .animation(.snappy, value: isFocused)
                }
        } else {
            content
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        toolbar.controls
                    }
                }
        }
    }
}
