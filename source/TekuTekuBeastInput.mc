using Toybox.WatchUi;
using Toybox.System;

class TekuTekuBeastInput extends WatchUi.BehaviorDelegate {
    var view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        self.view = view;
    }
    function onSelect() {
        view.selectAction();
        return true;
    }
    function onNextPage() {
        view.switchPage(1);
        return true;
    }
    function onPreviousPage() {
        view.switchPage(-1);
        return true;
    }
    function onBack() { return view.back(); }
    function onMenu() {
        var settings=System.getDeviceSettings();
        // Only use a dedicated app Menu input on touch-first watches. Never
        // intercept the normal UP long-press menu on five-button watches.
        if((settings has :inputButtons) && (settings.inputButtons&System.BUTTON_INPUT_UP)==0){view.switchPage(1);return true;}
        return false;
    }
    function onTap(event) { view.touch(event.getCoordinates()); return true; }
    function onSwipe(event) {
        var direction=event.getDirection();
        if(direction==WatchUi.SWIPE_UP){view.switchPage(1);return true;}
        if(direction==WatchUi.SWIPE_DOWN){view.switchPage(-1);return true;}
        if(direction==WatchUi.SWIPE_RIGHT){return view.back();}
        return false;
    }
}
