//
//  BarChart.swift
//  AdventureWorksMobile
//
//  Created by Jonah on 10/22/26.
//

import SwiftUI

struct BarChart: View {
    
    struct Entry: Identifiable {
        let label: String
        let value: Double
        var valueLabel: String? = nil
        
        var id: String { label }
    }
    
    let entries: [Entry]
    
    var totalLevels = 50
    var heightPerLevel: Int = 12
    
    private var maxValue: Double {
        entries.map(\.value).max() ?? 0
    }
    
    private func displayLevel(for value: Double) -> Int {
        guard maxValue > 0, value > 0 else { return 0 }
        let scaled = (value / maxValue * Double(totalLevels)).rounded(.up)
        return Int(scaled)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(entries) { entry in
                
                VStack {
                    if let valueLabel = entry.valueLabel {
                        Text(valueLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor)
                        .frame(height: CGFloat((displayLevel(for: entry.value))))
                    
                    Text(entry.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}


#Preview {
    BarChart(entries: [
        .init(label: "Mon", value: 18_400, valueLabel: "$18K"),
        .init(label: "Tue", value: 22_100, valueLabel: "$22K"),
        .init(label: "Wed", value: 15_800, valueLabel: "$16K"),
        .init(label: "Thu", value: 29_600, valueLabel: "$30K"),
        .init(label: "Fri", value: 34_200, valueLabel: "$34K"),
        .init(label: "Sat", value: 12_300, valueLabel: "$12K"),
        .init(label: "Sun", value: 9_100, valueLabel: "$9K"),
    ])
}
