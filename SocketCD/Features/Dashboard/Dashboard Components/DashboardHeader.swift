import SwiftUI

struct DashboardHeader: View {
    @ObservedObject var vehicle: Vehicle
    let updateOdometer: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(vehicle.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            odometerControl
        }
        .padding(.bottom, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var odometerControl: some View {
        Button(action: updateOdometer) {
            HStack {
                Text(
                    "\(Text(vehicle.odometer.formatted()).font(.title2.weight(.semibold)).monospacedDigit()) \(Text(vehicle.distanceUnit.abbreviated).font(.body).foregroundStyle(.secondary))"
                )
                .contentTransition(.numericText(value: Double(vehicle.odometer)))
                .animation(.default, value: vehicle.odometer)
                
                Image(systemName: "pencil")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.accent)
            }
            .contentShape(Rectangle())
            .accessibilityLabel("Odometer: \(vehicle.odometer.formatted()) \(vehicle.distanceUnit.abbreviated)")
        }
        .buttonStyle(.plain)
    }
}

