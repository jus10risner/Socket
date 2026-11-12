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
        content
            .safeAreaInset(edge: .bottom) {
                if isFocused {
                    toolbar
                }
            }
    }
}
