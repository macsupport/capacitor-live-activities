# @vetdrugs/capacitor-live-activities

Capacitor plugin for iOS Live Activities and Dynamic Island. Supports multiple concurrent timers for CRI, CPR, fluid therapy, and anesthesia monitoring in veterinary applications.

## Features

- **Multiple concurrent timers** - Run CRI, CPR, and other timers simultaneously
- **Dynamic Island support** - Compact and expanded views for iPhone 14 Pro+
- **Lock Screen widgets** - Visible even when phone is locked
- **Timer types** - CRI, CPR, Fluid, Anesthesia, Generic with appropriate icons/colors
- **Event callbacks** - Get notified when timers expire, are tapped, or dismissed

## Requirements

- iOS 16.1+ (Lock Screen Live Activities)
- iOS 16.2+ (Dynamic Island on iPhone 14 Pro and later)
- Capacitor 7.0+

## Installation

```bash
npm install @vetdrugs/capacitor-live-activities
npx cap sync
```

## iOS Setup

### 1. Add Live Activities Capability

In Xcode:
1. Select your app target
2. Go to "Signing & Capabilities"
3. Click "+ Capability"
4. Add "Push Notifications" (required for Live Activities)

### 2. Update Info.plist

Add to your `ios/App/App/Info.plist`:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### 3. Create Widget Extension

Live Activities require a Widget Extension to display the UI. You need to create one in Xcode:

1. File → New → Target → Widget Extension
2. Name it "VetDrugsTimerWidget"
3. Copy the `VetDrugsTimerAttributes.swift` and `VetDrugsTimerLiveActivity.swift` files to the widget extension
4. Make sure both files are included in both the main app and widget extension targets

## Usage

### Check Support

```typescript
import { LiveActivities } from '@vetdrugs/capacitor-live-activities';

const { supported, dynamicIsland } = await LiveActivities.isSupported();
console.log(`Live Activities: ${supported}, Dynamic Island: ${dynamicIsland}`);
```

### Start a Timer

```typescript
// CRI Timer
const result = await LiveActivities.startTimer({
  id: 'cri-fentanyl-123',
  type: 'cri',
  title: 'Fentanyl CRI',
  subtitle: '2.5 mcg/kg/hr',
  detail: 'Patient: Max',
  endTime: Date.now() + (60 * 60 * 1000), // 1 hour
  hapticOnExpire: true,
  soundOnExpire: true,
  customData: {
    patientId: 'patient-456',
    drugId: 'fentanyl'
  }
});

if (result.success) {
  console.log(`Timer started: ${result.id}`);
}

// CPR Timer (2 minutes for epinephrine cycle)
await LiveActivities.startTimer({
  id: 'cpr-epi-789',
  type: 'cpr',
  title: 'Epinephrine',
  subtitle: 'Next dose due',
  endTime: Date.now() + (2 * 60 * 1000), // 2 minutes
});
```

### Update a Timer

```typescript
await LiveActivities.updateTimer({
  id: 'cri-fentanyl-123',
  subtitle: '3.0 mcg/kg/hr', // Updated rate
  endTime: Date.now() + (30 * 60 * 1000), // Extended 30 more minutes
});
```

### End a Timer

```typescript
// End immediately
await LiveActivities.endTimer({
  id: 'cri-fentanyl-123',
  dismissalPolicy: 'immediate'
});

// End with final message, dismiss after 10 seconds
await LiveActivities.endTimer({
  id: 'cri-fentanyl-123',
  dismissalPolicy: 'after',
  dismissAfterSeconds: 10,
  finalMessage: 'Infusion Complete'
});
```

### Get Active Timers

```typescript
const { timers } = await LiveActivities.getActiveTimers();

for (const timer of timers) {
  console.log(`${timer.title}: ${timer.remainingSeconds}s remaining`);
}
```

### Listen for Events

```typescript
// Timer expired
LiveActivities.addListener('timerExpired', (event) => {
  console.log(`Timer ${event.id} expired!`);
  // Show alert, play sound, etc.
});

// Timer tapped (user interaction)
LiveActivities.addListener('timerTapped', (event) => {
  console.log(`Timer ${event.id} tapped`);
  // Navigate to relevant screen
});

// Timer dismissed
LiveActivities.addListener('timerDismissed', (event) => {
  console.log(`Timer ${event.id} dismissed`);
});
```

## Timer Types

| Type | Icon | Color | Use Case |
|------|------|-------|----------|
| `cri` | syringe.fill | Blue | Continuous Rate Infusion |
| `cpr` | heart.fill | Red | CPR drug timing |
| `fluid` | drop.fill | Green | Fluid therapy |
| `anesthesia` | lungs.fill | Purple | Anesthesia monitoring |
| `generic` | timer | Gray | Other timers |

## API Reference

### Methods

| Method | Description |
|--------|-------------|
| `isSupported()` | Check if Live Activities are supported |
| `startTimer(options)` | Start a new timer activity |
| `updateTimer(options)` | Update an existing timer |
| `endTimer(options)` | End a specific timer |
| `endAllTimers()` | End all active timers |
| `getActiveTimers()` | Get list of active timers |
| `isTimerActive(id)` | Check if a timer is active |

### Events

| Event | Description |
|-------|-------------|
| `timerExpired` | Timer reached end time |
| `timerTapped` | User tapped the activity |
| `timerDismissed` | Activity was dismissed |

## Limitations

- Live Activities are iOS-only (16.1+)
- Dynamic Island only on iPhone 14 Pro and later
- Maximum 5 concurrent activities per app
- Activities automatically end after 8 hours
- Widget Extension is required for custom UI

## License

MIT
