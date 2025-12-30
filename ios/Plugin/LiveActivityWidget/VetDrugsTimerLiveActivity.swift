import ActivityKit
import WidgetKit
import SwiftUI

/// Live Activity Widget for VetDrugs Timer
/// Displays on Lock Screen and Dynamic Island
@available(iOS 16.2, *)
struct VetDrugsTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VetDrugsTimerAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenView(context: context)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    LeadingExpandedView(context: context)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    TrailingExpandedView(context: context)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    BottomExpandedView(context: context)
                }

                DynamicIslandExpandedRegion(.center) {
                    CenterExpandedView(context: context)
                }

            } compactLeading: {
                // Compact leading (icon)
                CompactLeadingView(context: context)

            } compactTrailing: {
                // Compact trailing (timer)
                CompactTrailingView(context: context)

            } minimal: {
                // Minimal view (when multiple activities)
                MinimalView(context: context)
            }
        }
    }
}

// MARK: - Lock Screen View

@available(iOS 16.2, *)
struct LockScreenView: View {
    let context: ActivityViewContext<VetDrugsTimerAttributes>

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: context.attributes.icon)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(context.attributes.accentColor)
                .frame(width: 44, height: 44)
                .background(context.attributes.accentColor.opacity(0.2))
                .clipShape(Circle())

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                if !context.state.subtitle.isEmpty {
                    Text(context.state.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                if !context.state.detail.isEmpty {
                    Text(context.state.detail)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Timer countdown
            VStack(alignment: .trailing, spacing: 2) {
                Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(context.attributes.accentColor)
                    .monospacedDigit()

                Text("remaining")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.black)
    }
}

// MARK: - Dynamic Island Expanded Views

@available(iOS 16.2, *)
struct LeadingExpandedView: View {
    let context: ActivityViewContext<VetDrugsTimerAttributes>

    var body: some View {
        Image(systemName: context.attributes.icon)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(context.attributes.accentColor)
    }
}

@available(iOS 16.2, *)
struct TrailingExpandedView: View {
    let context: ActivityViewContext<VetDrugsTimerAttributes>

    var body: some View {
        Text(timerInterval: Date()...context.state.endTime, countsDown: true)
            .font(.system(size: 24, weight: .bold, design: .monospaced))
            .foregroundColor(context.attributes.accentColor)
            .monospacedDigit()
    }
}

@available(iOS 16.2, *)
struct CenterExpandedView: View {
    let context: ActivityViewContext<VetDrugsTimerAttributes>

    var body: some View {
        VStack(spacing: 2) {
            Text(context.state.title)
                .font(.headline)
                .fontWeight(.bold)

            if !context.state.subtitle.isEmpty {
                Text(context.state.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

@available(iOS 16.2, *)
struct BottomExpandedView: View {
    let context: ActivityViewContext<VetDrugsTimerAttributes>

    var body: some View {
        if !context.state.detail.isEmpty {
            Text(context.state.detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Dynamic Island Compact Views

@available(iOS 16.2, *)
struct CompactLeadingView: View {
    let context: ActivityViewContext<VetDrugsTimerAttributes>

    var body: some View {
        Image(systemName: context.attributes.icon)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(context.attributes.accentColor)
    }
}

@available(iOS 16.2, *)
struct CompactTrailingView: View {
    let context: ActivityViewContext<VetDrugsTimerAttributes>

    var body: some View {
        Text(timerInterval: Date()...context.state.endTime, countsDown: true)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(context.attributes.accentColor)
            .monospacedDigit()
    }
}

// MARK: - Minimal View (Multiple Activities)

@available(iOS 16.2, *)
struct MinimalView: View {
    let context: ActivityViewContext<VetDrugsTimerAttributes>

    var body: some View {
        Image(systemName: context.attributes.icon)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(context.attributes.accentColor)
    }
}

// MARK: - Preview

@available(iOS 16.2, *)
struct VetDrugsTimerLiveActivity_Previews: PreviewProvider {
    static let attributes = VetDrugsTimerAttributes(
        id: "preview-1",
        timerType: "cri",
        icon: "syringe.fill",
        accentColorHex: "#007AFF"
    )

    static let contentState = VetDrugsTimerAttributes.ContentState(
        title: "Fentanyl CRI",
        subtitle: "2.5 mcg/kg/hr",
        detail: "Patient: Max",
        endTime: Date().addingTimeInterval(3600),
        customData: [:]
    )

    static var previews: some View {
        Group {
            attributes
                .previewContext(contentState, viewKind: .content)
                .previewDisplayName("Lock Screen")

            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.compact))
                .previewDisplayName("Dynamic Island Compact")

            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
                .previewDisplayName("Dynamic Island Expanded")

            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
                .previewDisplayName("Dynamic Island Minimal")
        }
    }
}
