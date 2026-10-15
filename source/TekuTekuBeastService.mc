using Toybox.Background;
using Toybox.System;

(:background)
class TekuTekuBeastService extends System.ServiceDelegate {
    function initialize() { ServiceDelegate.initialize(); }
    function onSteps() {
        var beast = new TekuTekuBeastState();
        beast.syncToday();
        Background.exit(null);
    }
}
