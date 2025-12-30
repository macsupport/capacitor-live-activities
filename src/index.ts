import { registerPlugin } from '@capacitor/core';
import type { LiveActivitiesPlugin } from './definitions';

const LiveActivities = registerPlugin<LiveActivitiesPlugin>('LiveActivities', {
  web: () => import('./web').then((m) => new m.LiveActivitiesWeb()),
});

export * from './definitions';
export { LiveActivities };
