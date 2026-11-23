import SwiftUI

struct DashboardHeader: View {
    @ObservedObject var vehicle: Vehicle
    let updateOdometer: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(vehicle.name)
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            odometerControl
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var odometerControl: some View {
        HStack {
            Text(
                "\(Text(vehicle.odometer.formatted()).font(.title.bold()).monospacedDigit().kerning(-0.6)) \(Text(vehicle.distanceUnit.abbreviated).font(.title3.weight(.medium)).foregroundStyle(.secondary))"
            )
            .contentTransition(.numericText(value: Double(vehicle.odometer)))
            .animation(.default, value: vehicle.odometer)
            .onTapGesture(perform: updateOdometer)
            
            Button("Update", action: updateOdometer)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .dynamicTypeSize(.medium)
        }
        .contentShape(Rectangle())
        .accessibilityLabel("Odometer: \(vehicle.odometer.formatted()) \(vehicle.distanceUnit.abbreviated)")
    }
}

