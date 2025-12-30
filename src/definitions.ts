/**
 * Live Activities Plugin for iOS Dynamic Island and Lock Screen
 * Supports multiple concurrent timers for CRI, CPR, and other veterinary use cases
 */

export interface LiveActivitiesPlugin {
  /**
   * Check if Live Activities are supported on this device
   * Requires iOS 16.1+ and iPhone 14 Pro+ for Dynamic Island
   */
  isSupported(): Promise<{ supported: boolean; dynamicIsland: boolean }>;

  /**
   * Start a new timer activity
   * Creates a Live Activity on Lock Screen and Dynamic Island (if available)
   */
  startTimer(options: StartTimerOptions): Promise<StartTimerResult>;

  /**
   * Update an existing timer activity
   * Can change title, subtitle, or end time
   */
  updateTimer(options: UpdateTimerOptions): Promise<void>;

  /**
   * End a specific timer activity
   */
  endTimer(options: EndTimerOptions): Promise<void>;

  /**
   * End all active timer activities
   */
  endAllTimers(): Promise<{ endedCount: number }>;

  /**
   * Get all currently active timers
   */
  getActiveTimers(): Promise<{ timers: ActiveTimer[] }>;

  /**
   * Check if a specific timer is still active
   */
  isTimerActive(options: { id: string }): Promise<{ active: boolean }>;

  /**
   * Add a listener for timer events
   */
  addListener(
    eventName: 'timerExpired' | 'timerTapped' | 'timerDismissed',
    listenerFunc: (event: TimerEvent) => void
  ): Promise<{ remove: () => Promise<void> }>;

  /**
   * Remove all listeners for this plugin
   */
  removeAllListeners(): Promise<void>;
}

/**
 * Options for starting a new timer
 */
export interface StartTimerOptions {
  /** Unique identifier for this timer (e.g., 'cri-fentanyl-123') */
  id: string;

  /** Timer type for visual styling */
  type: 'cri' | 'cpr' | 'fluid' | 'anesthesia' | 'generic';

  /** Main title displayed (e.g., 'Fentanyl CRI') */
  title: string;

  /** Subtitle/detail line (e.g., '2.5 mcg/kg/hr') */
  subtitle?: string;

  /** Additional info line (e.g., 'Patient: Max') */
  detail?: string;

  /** Timer end time as Unix timestamp in milliseconds */
  endTime: number;

  /** SF Symbol name for the icon (default based on type) */
  icon?: string;

  /** Accent color as hex string (default based on type) */
  accentColor?: string;

  /** Whether to play haptic feedback on expiration */
  hapticOnExpire?: boolean;

  /** Whether to play sound on expiration */
  soundOnExpire?: boolean;

  /** Custom data to store with the timer */
  customData?: Record<string, string>;
}

/**
 * Result from starting a timer
 */
export interface StartTimerResult {
  /** Whether the timer was started successfully */
  success: boolean;

  /** The timer ID */
  id: string;

  /** Activity token for tracking */
  activityToken?: string;

  /** Error message if failed */
  error?: string;
}

/**
 * Options for updating an existing timer
 */
export interface UpdateTimerOptions {
  /** ID of the timer to update */
  id: string;

  /** New title (optional) */
  title?: string;

  /** New subtitle (optional) */
  subtitle?: string;

  /** New detail line (optional) */
  detail?: string;

  /** New end time as Unix timestamp in milliseconds (optional) */
  endTime?: number;

  /** Updated custom data (optional) */
  customData?: Record<string, string>;
}

/**
 * Options for ending a timer
 */
export interface EndTimerOptions {
  /** ID of the timer to end */
  id: string;

  /** How to dismiss the activity */
  dismissalPolicy?: 'immediate' | 'after' | 'default';

  /** Seconds to show final state before dismissing (for 'after' policy) */
  dismissAfterSeconds?: number;

  /** Final message to show (optional) */
  finalMessage?: string;
}

/**
 * Active timer information
 */
export interface ActiveTimer {
  /** Timer ID */
  id: string;

  /** Timer type */
  type: 'cri' | 'cpr' | 'fluid' | 'anesthesia' | 'generic';

  /** Title */
  title: string;

  /** Subtitle */
  subtitle?: string;

  /** Detail */
  detail?: string;

  /** End time as Unix timestamp */
  endTime: number;

  /** Time remaining in seconds */
  remainingSeconds: number;

  /** Whether the timer has expired */
  expired: boolean;

  /** When the timer was started */
  startedAt: number;

  /** Custom data */
  customData?: Record<string, string>;
}

/**
 * Timer event data
 */
export interface TimerEvent {
  /** Timer ID */
  id: string;

  /** Event type */
  eventType: 'expired' | 'tapped' | 'dismissed';

  /** Timer type */
  type: 'cri' | 'cpr' | 'fluid' | 'anesthesia' | 'generic';

  /** Timer title */
  title: string;

  /** Custom data */
  customData?: Record<string, string>;

  /** Timestamp of the event */
  timestamp: number;
}
