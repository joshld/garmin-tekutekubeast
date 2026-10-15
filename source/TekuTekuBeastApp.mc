using Toybox.Application;
using Toybox.Background;
using Toybox.WatchUi;

(:background)
class TekuTekuBeastApp extends Application.AppBase {
    var gameView = null;
    function initialize() { AppBase.initialize(); }
    function onStart(state) {
        if (!Background.getStepsEventRegistered()) {
            Background.registerForStepsEvent();
        }
    }
    function getInitialView() {
        var view = new TekuTekuBeastView();
        gameView = view;
        return [view, new TekuTekuBeastInput(view)];
    }
    function onStorageChanged() {
        if(gameView != null && !gameView.beast.dev){
            gameView.beast.data=null;
            gameView.beast.syncHistory();
            WatchUi.requestUpdate();
        }
    }
    function getServiceDelegate() {
        return [new TekuTekuBeastService()];
    }
}
