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
        return [new TekuTekuBeastView(), new TekuTekuBeastInput()];
    }
    function getServiceDelegate() {
        return [new TekuTekuBeastService()];
    }
}
