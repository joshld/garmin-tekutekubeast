using Toybox.Application;
using Toybox.Background;
using Toybox.WatchUi;

(:background)
class TekuTekuBeastApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function onStart(state) {
        if (!Background.getStepsEventRegistered()) {
            Background.registerForStepsEvent();
        }
    }
    function getInitialView() {
        var view = new TekuTekuBeastView();
        return [view, new TekuTekuBeastInput(view)];
    }
    function getServiceDelegate() {
        return [new TekuTekuBeastService()];
    }
}
