using Toybox.Background;
using Toybox.System;

(:background)
class TekuTekuBeastService extends System.ServiceDelegate {
    function initialize() { ServiceDelegate.initialize(); }
    function onSteps() {
        var beast = new TekuTekuBeastState();
        beast.syncToday();
        var stats=System.getSystemStats();
        System.println("BACKGROUND_MEMORY: used="+stats.usedMemory+" total="+stats.totalMemory);
        Background.exit(null);
    }
    // Silent schedule reconciliation; never import a foreground view or feedback.
    function onSleepTime(){onSteps();}
    function onWakeTime(){onSteps();}
}
