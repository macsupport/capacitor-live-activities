#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(LiveActivitiesPlugin, "LiveActivities",
    CAP_PLUGIN_METHOD(isSupported, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(startTimer, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(updateTimer, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(endTimer, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(endAllTimers, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getActiveTimers, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(isTimerActive, CAPPluginReturnPromise);
)
