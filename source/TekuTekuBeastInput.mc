using Toybox.WatchUi;

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
}
