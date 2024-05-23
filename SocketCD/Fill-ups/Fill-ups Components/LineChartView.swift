//
//  LineChartView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct LineChartView: View {
    let data: [Double]
    let average: Double
    private let maxY: Double
    private let minY: Double
    
    init(data: [Double], average: Double) {
        self.data = data
        self.average = average
        maxY = data.max() ?? 0
        minY = data.min() ?? 0
    }
    
    @State private var percentage: CGFloat = 0
    
    var body: some View {
        chartView
            .onAppear { animateLineChart() }
    }
    
    
    // MARK: - Views
    
    private var chartView: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    let maxY = data.max() ?? 0
                    let minY = data.min() ?? 0
                    let yAxis = maxY - minY
                    
                    if data.count >= 2 {
                        Path { path in
                            let yPosition = (1 - CGFloat((average - minY) / yAxis)) * geo.size.height
                            
                            path.move(to: CGPoint(x: 0, y: yPosition))
                            
                            path.addLine(to: CGPoint(x: geo.size.width, y: yPosition))
                        }
                        .stroke(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5]))
                    }
                    
                    Path { path in
                        for index in data.indices {
                            let xPosition = geo.size.width / CGFloat(data.count) * CGFloat(index)// removed + 1 from index
                            let yPosition = (1 - CGFloat((data[index] - minY) / yAxis)) * geo.size.height
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: xPosition, y: yPosition))
                            }
                            
                            path.addLine(to: CGPoint(x: xPosition, y: yPosition))
                        }
                    }
                    .trim(from: 0, to: percentage)
                    .stroke(Color.selectedColor(for: .fillupsTheme), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }
    
    
    // MARK: - Methods
    
    func animateLineChart() {
        withAnimation(.snappy) {
            percentage = 1.0
        }
    }
}

#Preview {
    LineChartView(data: [23.4, 22.6, 26.4, 30.1, 23.9, 24.2, 28.7], average: 25.6)
}
