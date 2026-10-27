/// The stock status icon.
struct StockStatusIcon: View {
    let level: StockLevel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State var isVisible = false

    var body: some View {
        let status = level.status
        let color = level.band.color

        Image(systemName: status.systemImage)
            .font(.title3)
            .foregroundStyle(color)
            // Glow when urgent, and pulse when critical unless Reduce Motion is on.
            .shadow(color: status.isUrgent ? color.opacity(0.8) : .clear,
                    radius: status.isUrgent ? 6 : 0)
            .symbolEffect(.pulse.wholeSymbol, isActive: isVisible && status.pulses && !reduceMotion)
            .frame(minWidth: 28)
            .accessibilityHidden(true)
            .onAppear { isVisible = true }
            .onDisappear() { isVisible = false }
    }
}