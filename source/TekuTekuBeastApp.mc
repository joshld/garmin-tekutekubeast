using Toybox.Application;
using Toybox.Background;
using Toybox.WatchUi;

(:background, :glance)
class TekuTekuBeastApp extends Application.AppBase {
    var gameView = null;
    var activeView = null;
    var launchedFromGlance=false;
    function onInactive(state) { if(activeView!=null){activeView.onHide();} }
    function onActive(state) { if(activeView!=null && activeView.refresher==null){activeView.onShow();} }
    function initialize() { AppBase.initialize(); }
    function onStart(state) {
        if(state!=null && state.hasKey(:launchedFromGlance)){launchedFromGlance=state[:launchedFromGlance];}
    }
    function getGlanceView() { return [new TekuTekuBeastGlanceView()]; }
    function registerSteps() {
        if (!Background.getStepsEventRegistered()) {
            Background.registerForStepsEvent();
        }
        try{
            if((Background has :getSleepEventRegistered) && !Background.getSleepEventRegistered()){Background.registerForSleepEvent();}
            if((Background has :getWakeEventRegistered) && !Background.getWakeEventRegistered()){Background.registerForWakeEvent();}
        }catch(e instanceof Toybox.Lang.Exception){Toybox.System.println("Sleep callback registration unavailable");}
    }
    function getInitialView() {
        registerSteps();
        var view = new TekuTekuBeastView();
        gameView = view;
        return [view, new TekuTekuBeastInput(view)];
    }
    function onStorageChanged() {
        if(activeView != null && !activeView.beast.dev){
            activeView.beast.data=null;
            activeView.beast.syncHistory();
            WatchUi.requestUpdate();
        }
    }
    function getServiceDelegate() {
        return [new TekuTekuBeastService()];
    }
}
