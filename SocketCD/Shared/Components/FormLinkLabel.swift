import SwiftUI

// Used for navigation link buttons inside forms (e.g. the Category selector button in AddEditRepairView)
struct FormLinkLabel<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 10) {
            content

            Image(systemName: "chevron.forward")
                .fontWeight(.semibold)
                .imageScale(.small)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
    }
}
