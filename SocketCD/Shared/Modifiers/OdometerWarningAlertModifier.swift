//
//  OdometerWarningAlertModifier.swift
//  SocketCD
//

import SwiftUI

private struct OdometerWarningAlertModifier: ViewModifier {
    @Binding var warning: OdometerWarning?

    let entered: Int?
    let current: Int?
    let distanceUnit: String
    let confirmationTitle: LocalizedStringResource
    let cancellationTitle: LocalizedStringResource
    let onConfirm: () -> Void
    let onCancel: () -> Void

    func body(content: Content) -> some View {
        content.alert(
            "Is This Correct?",
            item: $warning
        ) { _ in
            Button(cancellationTitle, role: .cancel, action: onCancel)
            Button(confirmationTitle, action: onConfirm)
        } message: { warning in
            if let entered, let current {
                Text(
                    warning.message(
                        entered: entered,
                        current: current,
                        distanceUnit: distanceUnit
                    )
                )
            }
        }
    }
}

extension View {
    func odometerWarningAlert(
        warning: Binding<OdometerWarning?>,
        entered: Int?,
        current: Int?,
        distanceUnit: String,
        confirmationTitle: LocalizedStringResource = "Save Anyway",
        cancellationTitle: LocalizedStringResource = "Keep Editing",
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void = {}
    ) -> some View {
        modifier(
            OdometerWarningAlertModifier(
                warning: warning,
                entered: entered,
                current: current,
                distanceUnit: distanceUnit,
                confirmationTitle: confirmationTitle,
                cancellationTitle: cancellationTitle,
                onConfirm: onConfirm,
                onCancel: onCancel
            )
        )
    }
}
