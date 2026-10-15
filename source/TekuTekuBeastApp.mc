using Toybox.Application;
using Toybox.Background;
using Toybox.WatchUi;

(:background, :glance)
class TekuTekuBeastApp extends Application.AppBase {
    var gameView = null;
    var activeView = null;
    function onInactive(state) { if(activeView!=null){activeView.onHide();} }
    function onActive(state) { if(activeView!=null && activeView.refresher==null){activeView.onShow();} }
    function initialize() { AppBase.initialize(); }
    function onStart(state) {
    }
    function getGlanceView() { return [new TekuTekuBeastGlanceView()]; }
    function registerSteps() {
        if (!Background.getStepsEventRegistered()) {
            Background.registerForStepsEvent();
        }
    }
    function getInitialView() {
        registerSteps();
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
