using Toybox.WatchUi;

class StepPalInput extends WatchUi.BehaviorDelegate {
    function initialize() { BehaviorDelegate.initialize(); }
    function onSelect() {
        WatchUi.getCurrentView()[0].selectAction();
        return true;
    }
    function onNextPage() {
        WatchUi.getCurrentView()[0].switchPage(1);
        return true;
    }
    function onPreviousPage() {
        WatchUi.getCurrentView()[0].switchPage(-1);
        return true;
    }
}
