import SwiftUI

protocol NumericInputValue: Equatable {
    static var allowsDecimals: Bool { get }
    static func parseInput(_ text: String) -> Self?
    func inputText(locale: Locale) -> String
}

extension Int: NumericInputValue {
    static var allowsDecimals: Bool { false }
    static func parseInput(_ text: String) -> Int? { Int(text) }
    func inputText(locale: Locale) -> String { String(self) }
}

extension Double: NumericInputValue {
    static var allowsDecimals: Bool { true }
    static func parseInput(_ text: String) -> Double? {
        guard let value = Double(text), value.isFinite else { return nil }
        return value
    }
    func inputText(locale: Locale) -> String {
        formatted(.number.grouping(.never).precision(.fractionLength(0...)).locale(locale))
    }
}

/// Keeps the user's text visible and shows a small explanation for invalid input.
struct NumericInput<Value: NumericInputValue, Field: Hashable>: View {
    @Environment(\.locale) private var locale
    @Binding private var value: Value?
    private let title: LocalizedStringKey
    private let focus: FocusState<Field?>.Binding
    private let field: Field
    @State private var text = ""
    @State private var initialized = false
    @State private var showingError = false

    init(_ title: LocalizedStringKey, value: Binding<Value?>, focus: FocusState<Field?>.Binding, field: Field) {
        self.title = title
        _value = value
        self.focus = focus
        self.field = field
    }

    // Settings have nonoptional values: retain the last valid setting on invalid input.
    init(_ title: LocalizedStringKey, value: Binding<Value>, focus: FocusState<Field?>.Binding, field: Field) {
        self.init(title, value: Binding<Value?>(
            get: { value.wrappedValue },
            set: { if let newValue = $0 { value.wrappedValue = newValue } }
        ), focus: focus, field: field)
    }

    private var parsedValue: Value? {
        var input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if Value.allowsDecimals {
            let separator = locale.decimalSeparator ?? "."
            guard separator == "." || !input.contains(".") else { return nil }
            input = input.replacingOccurrences(of: separator, with: ".")
        }
        let allowed = Value.allowsDecimals ? "0123456789." : "0123456789"
        guard input.allSatisfy({ allowed.contains($0) }),
              input.filter({ $0 == "." }).count <= 1 else { return nil }
        return Value.parseInput(input)
    }

    private var isInvalid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedValue == nil
    }

    private var errorMessage: LocalizedStringKey {
        Value.allowsDecimals
            ? "Enter a number, such as 20 or \(20.5.formatted(.number.grouping(.never).locale(locale)))."
            : "Enter a whole number, such as 500."
    }

    var body: some View {
        HStack {
            TextField(title, text: Binding(
                get: { text },
                set: {
                    text = $0
                    value = parsedValue
                    if !isInvalid { showingError = false }
                }
            ))
            .keyboardType(Value.allowsDecimals ? .decimalPad : .numberPad)
            .focused(focus, equals: field)
            .selectAllOnFocus()

            if isInvalid {
                Button {
                    showingError = true
                } label: {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Invalid number")
                .accessibilityHint(Text(errorMessage))
                .popover(isPresented: $showingError) {
                    Text(errorMessage)
                        .foregroundStyle(.primary)
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(idealWidth: 200)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                }
            }
        }
        .onAppear {
            guard !initialized else { return }
            text = value?.inputText(locale: locale) ?? ""
            initialized = true
        }
        .onChange(of: value) { _, newValue in
            // Reflect external changes without replacing invalid or unfinished input.
            if newValue != parsedValue {
                text = newValue?.inputText(locale: locale) ?? ""
                showingError = false
            }
        }
    }
}
