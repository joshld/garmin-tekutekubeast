using Toybox.Background;
using Toybox.System;

(:background)
class StepPalService extends System.ServiceDelegate {
    function initialize() { ServiceDelegate.initialize(); }
    function onSteps() {
        var pal = new StepPalState();
        pal.syncToday();
        Background.exit(null);
    }
}
