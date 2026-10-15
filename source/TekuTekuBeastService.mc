using Toybox.Background;
using Toybox.System;

(:background)
class TekuTekuBeastService extends System.ServiceDelegate {
    function initialize() { ServiceDelegate.initialize(); }
    function onSteps() {
        var pal = new TekuTekuBeastState();
        pal.syncToday();
        Background.exit(null);
    }
}
