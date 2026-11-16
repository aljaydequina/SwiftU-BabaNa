import ActivityKit
import WidgetKit
import SwiftUI

private enum LiveTheme {
    static let forest = Color(red: 0.05, green: 0.25, blue: 0.20)
    static let mint = Color(red: 0.43, green: 0.85, blue: 0.65)
}

struct BabaNaTripLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TripActivityAttributes.self) { context in
            TripLockScreenView(context: context)
                .activityBackgroundTint(LiveTheme.forest)
                .activitySystemActionForegroundColor(LiveTheme.mint)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: icon(for: context.state.phase))
                        .font(.title2)
                        .foregroundStyle(LiveTheme.mint)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.distanceText)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(LiveTheme.mint)
                        .contentTransition(.numericText())
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.destinationName)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        ProgressView(value: context.state.progress)
                            .tint(LiveTheme.mint)
                        Text(statusText(context))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: icon(for: context.state.phase))
                    .foregroundStyle(LiveTheme.mint)
            } compactTrailing: {
                Text(context.state.distanceText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LiveTheme.mint)
                    .contentTransition(.numericText())
            } minimal: {
                Image(systemName: icon(for: context.state.phase))
                    .foregroundStyle(LiveTheme.mint)
            }
            .keylineTint(LiveTheme.mint)
        }
    }
}

private struct TripLockScreenView: View {
    let context: ActivityViewContext<TripActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "bus.fill")
                Text("BABANA · TRIP")
                    .tracking(1.1)
                Spacer(minLength: 0)
                Text("Reminder at \(TripActivityAttributes.format(context.attributes.reminderMeters))")
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white.opacity(0.7))

            HStack(alignment: .firstTextBaseline) {
                Text(context.attributes.destinationName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Spacer(minLength: 8)
                Text(context.state.distanceText)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(LiveTheme.mint)
                    .contentTransition(.numericText())
            }

            ProgressView(value: context.state.progress)
                .tint(LiveTheme.mint)

            Label(statusText(context), systemImage: icon(for: context.state.phase))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
        }
        .padding(16)
    }
}

private func icon(for phase: TripActivityPhase) -> String {
    switch phase {
    case .locating: return "location.magnifyingglass"
    case .onTheWay: return "bus.fill"
    case .approaching: return "bell.fill"
    case .arrived: return "figure.walk.departure"
    }
}

private func statusText(_ context: ActivityViewContext<TripActivityAttributes>) -> String {
    if context.isStale && context.state.phase != .arrived {
        return "Buksan ang BabaNa para ma-update ang distansya"
    }
    switch context.state.phase {
    case .locating: return "Hinahanap ang GPS…"
    case .onTheWay: return "Papunta ka na. Ire-remind ka namin."
    case .approaching: return "Malapit ka na. Ihanda na ang gamit mo."
    case .arrived: return "Baba na! Nandito ka na sa stop mo."
    }
}
