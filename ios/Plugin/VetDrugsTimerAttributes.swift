import ActivityKit
import SwiftUI

/// Activity Attributes for VetDrugs Timer Live Activities
/// Supports CRI timers, CPR timers, fluid therapy, and anesthesia monitoring
@available(iOS 16.2, *)
public struct VetDrugsTimerAttributes: ActivityAttributes {

    // MARK: - Static Attributes (set when activity starts)

    /// Unique identifier for this timer
    public let id: String

    /// Type of timer: "cri", "cpr", "fluid", "anesthesia", "generic"
    public let timerType: String

    /// SF Symbol name for the icon
    public let icon: String

    /// Accent color as hex string (e.g., "#FF3B30")
    public let accentColorHex: String

    // MARK: - Dynamic Content State (can be updated)

    public struct ContentState: Codable, Hashable {
        /// Main title (e.g., "Fentanyl CRI")
        public var title: String

        /// Subtitle (e.g., "2.5 mcg/kg/hr")
        public var subtitle: String

        /// Additional detail (e.g., "Patient: Max")
        public var detail: String

        /// When the timer ends
        public var endTime: Date

        /// Custom data dictionary
        public var customData: [String: String]

        public init(title: String, subtitle: String, detail: String, endTime: Date, customData: [String: String] = [:]) {
            self.title = title
            self.subtitle = subtitle
            self.detail = detail
            self.endTime = endTime
            self.customData = customData
        }
    }

    // MARK: - Computed Properties

    /// Parse accent color from hex string
    public var accentColor: Color {
        Color(hex: accentColorHex) ?? .blue
    }
}

// MARK: - Color Extension for Hex Parsing

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
