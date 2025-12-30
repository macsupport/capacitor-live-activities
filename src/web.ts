import { WebPlugin } from '@capacitor/core';
import type {
  LiveActivitiesPlugin,
  StartTimerOptions,
  StartTimerResult,
  UpdateTimerOptions,
  EndTimerOptions,
  ActiveTimer,
  TimerEvent,
} from './definitions';

/**
 * Web implementation - provides mock functionality for development/testing
 * Live Activities are iOS-only, so this just tracks timers in memory
 */
export class LiveActivitiesWeb extends WebPlugin implements LiveActivitiesPlugin {
  private timers: Map<string, ActiveTimer> = new Map();
  private timerIntervals: Map<string, number> = new Map();

  async isSupported(): Promise<{ supported: boolean; dynamicIsland: boolean }> {
    // Web never supports Live Activities
    return { supported: false, dynamicIsland: false };
  }

  async startTimer(options: StartTimerOptions): Promise<StartTimerResult> {
    console.log('📱 LiveActivities (Web): Starting timer', options);

    // Simulate timer in memory for development
    const timer: ActiveTimer = {
      id: options.id,
      type: options.type,
      title: options.title,
      subtitle: options.subtitle,
      detail: options.detail,
      endTime: options.endTime,
      remainingSeconds: Math.floor((options.endTime - Date.now()) / 1000),
      expired: false,
      startedAt: Date.now(),
      customData: options.customData,
    };

    this.timers.set(options.id, timer);

    // Set up interval to track expiration
    const intervalId = window.setInterval(() => {
      const t = this.timers.get(options.id);
      if (t) {
        t.remainingSeconds = Math.floor((t.endTime - Date.now()) / 1000);
        if (t.remainingSeconds <= 0 && !t.expired) {
          t.expired = true;
          console.log('⏰ LiveActivities (Web): Timer expired', options.id);
          this.notifyListeners('timerExpired', {
            id: options.id,
            eventType: 'expired',
            type: options.type,
            title: options.title,
            customData: options.customData,
            timestamp: Date.now(),
          } as TimerEvent);
        }
      }
    }, 1000);

    this.timerIntervals.set(options.id, intervalId);

    return {
      success: true,
      id: options.id,
      activityToken: `web-mock-${options.id}`,
    };
  }

  async updateTimer(options: UpdateTimerOptions): Promise<void> {
    console.log('📱 LiveActivities (Web): Updating timer', options);

    const timer = this.timers.get(options.id);
    if (!timer) {
      throw new Error(`Timer not found: ${options.id}`);
    }

    if (options.title !== undefined) timer.title = options.title;
    if (options.subtitle !== undefined) timer.subtitle = options.subtitle;
    if (options.detail !== undefined) timer.detail = options.detail;
    if (options.endTime !== undefined) {
      timer.endTime = options.endTime;
      timer.remainingSeconds = Math.floor((options.endTime - Date.now()) / 1000);
      timer.expired = timer.remainingSeconds <= 0;
    }
    if (options.customData !== undefined) timer.customData = options.customData;
  }

  async endTimer(options: EndTimerOptions): Promise<void> {
    console.log('📱 LiveActivities (Web): Ending timer', options);

    const intervalId = this.timerIntervals.get(options.id);
    if (intervalId) {
      clearInterval(intervalId);
      this.timerIntervals.delete(options.id);
    }

    this.timers.delete(options.id);

    this.notifyListeners('timerDismissed', {
      id: options.id,
      eventType: 'dismissed',
      type: 'generic',
      title: '',
      timestamp: Date.now(),
    } as TimerEvent);
  }

  async endAllTimers(): Promise<{ endedCount: number }> {
    console.log('📱 LiveActivities (Web): Ending all timers');

    const count = this.timers.size;

    // Clear all intervals
    this.timerIntervals.forEach((intervalId) => clearInterval(intervalId));
    this.timerIntervals.clear();
    this.timers.clear();

    return { endedCount: count };
  }

  async getActiveTimers(): Promise<{ timers: ActiveTimer[] }> {
    // Update remaining times before returning
    const timers: ActiveTimer[] = [];
    this.timers.forEach((timer) => {
      timer.remainingSeconds = Math.floor((timer.endTime - Date.now()) / 1000);
      timer.expired = timer.remainingSeconds <= 0;
      timers.push({ ...timer });
    });

    return { timers };
  }

  async isTimerActive(options: { id: string }): Promise<{ active: boolean }> {
    const timer = this.timers.get(options.id);
    return { active: timer !== undefined && !timer.expired };
  }
}
