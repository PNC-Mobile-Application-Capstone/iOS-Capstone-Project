//
//  StockStatusIcon.swift
//  AdventureWorksMobile
//
import SwiftUI

/// The stock status icon.
struct StockStatusIcon: View {
    let level: StockLevel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    
    private var icon: some View {
        
        let status = level.status
        let color = level.band.color

        return Image(systemName: status.systemImage)
            .font(.title3)
            .foregroundStyle(color)
            // Glow when urgent, and pulse when critical unless Reduce Motion is on.
            .shadow(color: status.isUrgent ? color.opacity(0.8) : .clear,
                    radius: status.isUrgent ? 6 : 0)
            .frame(minWidth: 28)
            .accessibilityHidden(true)
            
    }
    
    // A fixed start date, so every icon ticks at the same moments.
    private static let pulseClock = PeriodicTimelineSchedule(
        from: Date(timeIntervalSinceReferenceDate: 0), by: 1.5)

    var body: some View {
        let status = level.status
        
        if status.pulses && !reduceMotion {
            TimelineView(Self.pulseClock) { context in
                icon
                    // One pulse each time the shared clock ticks.
                    .symbolEffect(.pulse.wholeSymbol, options: .nonRepeating, value: context.date)
            }
        } else { icon }

    }
}
