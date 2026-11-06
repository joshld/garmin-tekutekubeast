using Toybox.WatchUi;
using Toybox.System;

class TekuTekuBeastInput extends WatchUi.BehaviorDelegate {
    var view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        self.view = view;
    }
    function onSelect() {
        view.perform("select",null);
        return true;
    }
    function onNextPage() {
        view.perform("switch",1);
        return true;
    }
    function onPreviousPage() {
        view.perform("switch",-1);
        return true;
    }
    function onBack() { return view.perform("back",null); }
    function onMenu() {
        var settings=System.getDeviceSettings();
        // Only use a dedicated app Menu input on touch-first watches. Never
        // intercept the normal UP long-press menu on five-button watches.
        if((settings has :inputButtons) && (settings.inputButtons&System.BUTTON_INPUT_UP)==0){view.perform("switch",1);return true;}
        view.perform("activity",null);return false;
    }
    function onTap(event) { view.perform("touch",event.getCoordinates()); return true; }
    function onSwipe(event) {
        var direction=event.getDirection();
        if(direction==WatchUi.SWIPE_UP){view.perform("switch",1);return true;}
        if(direction==WatchUi.SWIPE_DOWN){view.perform("switch",-1);return true;}
        if(direction==WatchUi.SWIPE_RIGHT){return view.perform("back",null);}
        view.perform("activity",null);return false;
    }
}
