import Foundation
import Capacitor
import ActivityKit
import AudioToolbox
import UIKit

@objc(LiveActivitiesPlugin)
public class LiveActivitiesPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LiveActivitiesPlugin"
    public let jsName = "LiveActivities"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isSupported", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "startTimer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "updateTimer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "endTimer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "endAllTimers", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getActiveTimers", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isTimerActive", returnType: CAPPluginReturnPromise)
    ]

    // Track activities by ID - stored as Any to avoid iOS version issues at declaration
    private var activeTimers: [String: Any] = [:]

    // Track timer metadata for haptic/sound on expire
    private struct TimerMetadata {
        let endTime: Date
        let hapticOnExpire: Bool
        let soundOnExpire: Bool
        var hasExpired: Bool = false
    }
    private var timerMetadata: [String: TimerMetadata] = [:]
    private var expirationCheckTimer: Timer?

    // MARK: - Helper to get typed activity
    @available(iOS 16.2, *)
    private func getActivity(_ id: String) -> Activity<VetDrugsTimerAttributes>? {
        return activeTimers[id] as? Activity<VetDrugsTimerAttributes>
    }

    // MARK: - isSupported

    @objc func isSupported(_ call: CAPPluginCall) {
        if #available(iOS 16.2, *) {
            let supported = ActivityAuthorizationInfo().areActivitiesEnabled

            // Check for Dynamic Island (iPhone 14 Pro and later)
            let hasDynamicIsland = supported && UIDevice.current.userInterfaceIdiom == .phone

            call.resolve([
                "supported": supported,
                "dynamicIsland": hasDynamicIsland
            ])
        } else {
            call.resolve([
                "supported": false,
                "dynamicIsland": false
            ])
        }
    }

    // MARK: - startTimer

    @objc func startTimer(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else {
            call.resolve([
                "success": false,
                "id": call.getString("id") ?? "",
                "error": "Live Activities require iOS 16.2 or later"
            ])
            return
        }

        guard let id = call.getString("id") else {
            call.reject("Timer ID is required")
            return
        }

        guard let title = call.getString("title") else {
            call.reject("Timer title is required")
            return
        }

        guard let endTime = call.getDouble("endTime") else {
            call.reject("Timer endTime is required")
            return
        }

        let timerType = call.getString("type") ?? "generic"
        let subtitle = call.getString("subtitle")
        let detail = call.getString("detail")
        let icon = call.getString("icon") ?? iconForType(timerType)
        let accentColor = call.getString("accentColor") ?? colorForType(timerType)
        let customData = call.getObject("customData") as? [String: String] ?? [:]
        let hapticOnExpire = call.getBool("hapticOnExpire") ?? true
        let soundOnExpire = call.getBool("soundOnExpire") ?? true

        // Convert milliseconds to Date
        let endDate = Date(timeIntervalSince1970: endTime / 1000)

        // Store metadata for expiration handling
        timerMetadata[id] = TimerMetadata(
            endTime: endDate,
            hapticOnExpire: hapticOnExpire,
            soundOnExpire: soundOnExpire
        )

        // Create the activity attributes
        let attributes = VetDrugsTimerAttributes(
            id: id,
            timerType: timerType,
            icon: icon,
            accentColorHex: accentColor
        )

        // Create the initial content state
        let initialState = VetDrugsTimerAttributes.ContentState(
            title: title,
            subtitle: subtitle ?? "",
            detail: detail ?? "",
            endTime: endDate,
            customData: customData
        )

        // Create activity content
        let content = ActivityContent(state: initialState, staleDate: endDate.addingTimeInterval(60))

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )

            // Store the activity
            activeTimers[id] = activity

            print("LiveActivities: Started timer '\(id)' - \(title)")

            // Start expiration check timer if not already running
            startExpirationCheckTimer()

            // Monitor for state changes
            Task {
                for await state in activity.activityStateUpdates {
                    await handleActivityStateChange(id: id, state: state)
                }
            }

            call.resolve([
                "success": true,
                "id": id,
                "activityToken": activity.id
            ])

        } catch {
            print("LiveActivities: Failed to start timer - \(error)")
            call.resolve([
                "success": false,
                "id": id,
                "error": error.localizedDescription
            ])
        }
    }

    // MARK: - updateTimer

    @objc func updateTimer(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else {
            call.reject("Live Activities require iOS 16.2 or later")
            return
        }

        guard let id = call.getString("id") else {
            call.reject("Timer ID is required")
            return
        }

        guard let activity = getActivity(id) else {
            call.reject("Timer not found: \(id)")
            return
        }

        // Get current state to merge with updates
        let currentState = activity.content.state

        let title = call.getString("title") ?? currentState.title
        let subtitle = call.getString("subtitle") ?? currentState.subtitle
        let detail = call.getString("detail") ?? currentState.detail
        let endTime = call.getDouble("endTime").map { Date(timeIntervalSince1970: $0 / 1000) } ?? currentState.endTime
        let customData = call.getObject("customData") as? [String: String] ?? currentState.customData

        let updatedState = VetDrugsTimerAttributes.ContentState(
            title: title,
            subtitle: subtitle,
            detail: detail,
            endTime: endTime,
            customData: customData
        )

        let content = ActivityContent(state: updatedState, staleDate: endTime.addingTimeInterval(60))

        Task {
            await activity.update(content)
            print("LiveActivities: Updated timer '\(id)'")
            call.resolve()
        }
    }

    // MARK: - endTimer

    @objc func endTimer(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else {
            call.reject("Live Activities require iOS 16.2 or later")
            return
        }

        guard let id = call.getString("id") else {
            call.reject("Timer ID is required")
            return
        }

        guard let activity = getActivity(id) else {
            call.reject("Timer not found: \(id)")
            return
        }

        let dismissalPolicy = call.getString("dismissalPolicy") ?? "default"
        let dismissAfterSeconds = call.getDouble("dismissAfterSeconds") ?? 0
        let finalMessage = call.getString("finalMessage")

        Task {
            // Create final state if message provided
            var finalState = activity.content.state
            if let message = finalMessage {
                finalState = VetDrugsTimerAttributes.ContentState(
                    title: message,
                    subtitle: finalState.subtitle,
                    detail: "",
                    endTime: Date(),
                    customData: finalState.customData
                )
            }

            let finalContent = ActivityContent(state: finalState, staleDate: nil)

            let policy: ActivityUIDismissalPolicy
            switch dismissalPolicy {
            case "immediate":
                policy = .immediate
            case "after":
                policy = .after(Date().addingTimeInterval(dismissAfterSeconds))
            default:
                policy = .default
            }

            await activity.end(finalContent, dismissalPolicy: policy)
            activeTimers.removeValue(forKey: id)
            timerMetadata.removeValue(forKey: id)

            // Stop expiration timer if no more active timers
            if activeTimers.isEmpty {
                stopExpirationCheckTimer()
            }

            print("LiveActivities: Ended timer '\(id)'")

            // Notify JS
            notifyListeners("timerDismissed", data: [
                "id": id,
                "eventType": "dismissed",
                "timestamp": Date().timeIntervalSince1970 * 1000
            ])

            call.resolve()
        }
    }

    // MARK: - endAllTimers

    @objc func endAllTimers(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else {
            call.resolve(["endedCount": 0])
            return
        }

        let count = activeTimers.count

        Task {
            for (id, activityAny) in activeTimers {
                if let activity = activityAny as? Activity<VetDrugsTimerAttributes> {
                    await activity.end(nil, dismissalPolicy: .immediate)
                    print("LiveActivities: Ended timer '\(id)'")
                }
            }
            activeTimers.removeAll()
            timerMetadata.removeAll()
            stopExpirationCheckTimer()

            call.resolve(["endedCount": count])
        }
    }

    // MARK: - getActiveTimers

    @objc func getActiveTimers(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else {
            call.resolve(["timers": []])
            return
        }

        var timers: [[String: Any]] = []

        for (id, activityAny) in activeTimers {
            if let activity = activityAny as? Activity<VetDrugsTimerAttributes> {
                let state = activity.content.state
                let remainingSeconds = max(0, state.endTime.timeIntervalSince(Date()))

                timers.append([
                    "id": id,
                    "type": activity.attributes.timerType,
                    "title": state.title,
                    "subtitle": state.subtitle,
                    "detail": state.detail,
                    "endTime": state.endTime.timeIntervalSince1970 * 1000,
                    "remainingSeconds": Int(remainingSeconds),
                    "expired": remainingSeconds <= 0,
                    "startedAt": activity.content.state.endTime.timeIntervalSince1970 * 1000 - (remainingSeconds * 1000),
                    "customData": state.customData
                ])
            }
        }

        call.resolve(["timers": timers])
    }

    // MARK: - isTimerActive

    @objc func isTimerActive(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else {
            call.reject("Timer ID is required")
            return
        }

        if #available(iOS 16.2, *) {
            if let activity = getActivity(id) {
                let state = activity.content.state
                let remainingSeconds = state.endTime.timeIntervalSince(Date())
                call.resolve(["active": remainingSeconds > 0])
            } else {
                call.resolve(["active": false])
            }
        } else {
            call.resolve(["active": false])
        }
    }

    // MARK: - Private Helpers

    private func iconForType(_ type: String) -> String {
        switch type {
        case "cri": return "syringe.fill"
        case "cpr": return "heart.fill"
        case "fluid": return "drop.fill"
        case "anesthesia": return "lungs.fill"
        default: return "timer"
        }
    }

    private func colorForType(_ type: String) -> String {
        switch type {
        case "cri": return "#007AFF"      // Blue
        case "cpr": return "#FF3B30"      // Red
        case "fluid": return "#34C759"    // Green
        case "anesthesia": return "#AF52DE" // Purple
        default: return "#8E8E93"         // Gray
        }
    }

    @available(iOS 16.2, *)
    private func handleActivityStateChange(id: String, state: ActivityState) async {
        switch state {
        case .ended:
            activeTimers.removeValue(forKey: id)
            timerMetadata.removeValue(forKey: id)
            print("LiveActivities: Activity ended - \(id)")
            notifyListeners("timerExpired", data: [
                "id": id,
                "eventType": "expired",
                "timestamp": Date().timeIntervalSince1970 * 1000
            ])
        case .dismissed:
            activeTimers.removeValue(forKey: id)
            timerMetadata.removeValue(forKey: id)
            print("LiveActivities: Activity dismissed - \(id)")
        case .stale:
            print("LiveActivities: Activity stale - \(id)")
        case .active:
            print("LiveActivities: Activity active - \(id)")
        @unknown default:
            break
        }

        // Stop expiration timer if no more active timers
        if activeTimers.isEmpty {
            stopExpirationCheckTimer()
        }
    }

    // MARK: - Expiration Check Timer

    private func startExpirationCheckTimer() {
        // Don't start if already running
        guard expirationCheckTimer == nil else { return }

        DispatchQueue.main.async { [weak self] in
            self?.expirationCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.checkForExpiredTimers()
            }
        }
        print("LiveActivities: Started expiration check timer")
    }

    private func stopExpirationCheckTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.expirationCheckTimer?.invalidate()
            self?.expirationCheckTimer = nil
        }
        print("LiveActivities: Stopped expiration check timer")
    }

    private func checkForExpiredTimers() {
        let now = Date()

        for (id, var metadata) in timerMetadata {
            // Skip if already handled
            if metadata.hasExpired { continue }

            // Check if timer has expired
            if metadata.endTime <= now {
                metadata.hasExpired = true
                timerMetadata[id] = metadata

                print("LiveActivities: Timer expired - \(id)")

                // Trigger haptic feedback
                if metadata.hapticOnExpire {
                    triggerHapticFeedback()
                }

                // Trigger sound
                if metadata.soundOnExpire {
                    triggerExpirationSound()
                }

                // Notify JS
                notifyListeners("timerExpired", data: [
                    "id": id,
                    "eventType": "expired",
                    "timestamp": now.timeIntervalSince1970 * 1000
                ])

                // Update the Live Activity to show "Complete" state
                if #available(iOS 16.2, *) {
                    updateActivityToComplete(id: id)
                }
            }
        }
    }

    private func triggerHapticFeedback() {
        DispatchQueue.main.async {
            // Use notification feedback generator for strong haptic
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)

            // Follow up with impact feedback for emphasis
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.prepare()
                impact.impactOccurred()
            }
        }
        print("LiveActivities: Triggered haptic feedback")
    }

    private func triggerExpirationSound() {
        // Play system sound (tri-tone alert)
        AudioServicesPlaySystemSound(1007) // New mail sound - distinct but not alarming

        // Also vibrate
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

        print("LiveActivities: Triggered expiration sound")
    }

    @available(iOS 16.2, *)
    private func updateActivityToComplete(id: String) {
        guard let activity = getActivity(id) else { return }

        let currentState = activity.content.state
        let completedState = VetDrugsTimerAttributes.ContentState(
            title: "\(currentState.title) - Complete",
            subtitle: currentState.subtitle,
            detail: "Timer finished",
            endTime: Date(), // Set to now so UI shows "Complete"
            customData: currentState.customData
        )

        let content = ActivityContent(state: completedState, staleDate: nil)

        Task {
            await activity.update(content)
            print("LiveActivities: Updated activity to complete state - \(id)")
        }
    }
}
