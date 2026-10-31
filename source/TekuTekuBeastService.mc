using Toybox.Background;
using Toybox.System;

(:background)
class TekuTekuBeastService extends System.ServiceDelegate {
    function initialize() { ServiceDelegate.initialize(); }
    function onSteps(){reconcile(false);}
    function reconcile(forceSleep) {
        var began=System.getTimer();var beast = new BeastStateCore();beast.start();
        var info=GarminActivity.info();var steps=GarminActivity.steps(info);
        var minutes=GarminActivity.minutes(info);var pushes=GarminActivity.pushes(info);
        if(!forceSleep && beast.stepNoop(steps,minutes,pushes)){
            System.println("BACKGROUND_NOOP: writes=0 elapsedMs="+(System.getTimer()-began));Background.exit(null);return;
        }
        if(forceSleep){beast.refreshSleep();}beast.syncActivity(steps,minutes,pushes);
        var stats=System.getSystemStats();
        System.println("BACKGROUND_MEMORY: used="+stats.usedMemory+" total="+stats.totalMemory);
        System.println("BACKGROUND_WORK: writes="+beast.store.writes+" skipped="+beast.store.skipped+" elapsedMs="+(System.getTimer()-began));
        Background.exit(null);
    }
    // Silent schedule reconciliation; never import a foreground view or feedback.
    function onSleepTime(){reconcile(true);}
    function onWakeTime(){reconcile(true);}
}
