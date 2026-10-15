using Toybox.Application;
using Toybox.Background;
using Toybox.WatchUi;

(:background)
class StepPalApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function onStart(state) {
        if (!Background.getStepsEventRegistered()) {
            Background.registerForStepsEvent();
        }
    }
    function getInitialView() {
        return [new StepPalView(), new StepPalInput()];
    }
    function getServiceDelegate() {
        return [new StepPalService()];
    }
}
