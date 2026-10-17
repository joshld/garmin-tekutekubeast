using Toybox.Background;
using Toybox.System;
using Toybox.ActivityMonitor;

(:background)
class TekuTekuBeastService extends System.ServiceDelegate {
    function initialize() { ServiceDelegate.initialize(); }
    function onSteps(){reconcile(false);}
    function reconcile(forceSleep) {
        var began=System.getTimer();var beast = new TekuTekuBeastState();beast.start();
        var info=ActivityMonitor.getInfo();var minutes=null;var pushes=null;
        if(info has :activeMinutesDay){var active=info.activeMinutesDay;if(active!=null){minutes=active.moderate+active.vigorous;}}
        if(info has :pushes){pushes=info.pushes;}
        if(!forceSleep && beast.stepNoop(info.steps,minutes,pushes)){
            System.println("BACKGROUND_NOOP: writes=0 elapsedMs="+(System.getTimer()-began));Background.exit(null);return;
        }
        if(forceSleep){beast.refreshSleep();}beast.syncFromInfo(info);
        var stats=System.getSystemStats();
        System.println("BACKGROUND_MEMORY: used="+stats.usedMemory+" total="+stats.totalMemory);
        System.println("BACKGROUND_WORK: writes="+beast.store.writes+" skipped="+beast.store.skipped+" elapsedMs="+(System.getTimer()-began));
        Background.exit(null);
    }
    // Silent schedule reconciliation; never import a foreground view or feedback.
    function onSleepTime(){reconcile(true);}
    function onWakeTime(){reconcile(true);}
}
