using Toybox.Application;
using Toybox.WatchUi;

// A separate application ID and an entirely in-memory model protect real saves.
class ArtPreviewState extends TekuTekuBeastState {
    var previewStage;
    var previewFamily;
    function initialize() {
        TekuTekuBeastState.initialize();
        previewStage = 0;
        previewFamily = 0;
    }
    function start() {}
    function syncToday() {}
    function syncHistory() {}
    function stage() { return previewStage; }
    function xp() {
        if (previewStage == 0) { return 0; }
        if (previewStage == 1) { return 2500; }
        if (previewStage == 2) { return 25000; }
        if (previewStage == 3) { return 80000; }
        if (previewStage == 4) { return 170000; }
        return 325000;
    }
    function ageDays() { return previewStage * 5; }
    function family() { return previewStage < 3 ? 0 : previewFamily; }
    function getTodaySteps() { return 12345; }
    function friendship() { return 60; }
    function snacks() { return 3; }
    function patsToday() { return 1; }
    function pat() { return true; }
    function feed() { return true; }
    function nextPreview() {
        // First three stages, followed by all twelve existing family-stage paths.
        if (previewStage < 2) { previewStage++; return; }
        if (previewStage == 2) { previewStage = 3; previewFamily = 1; return; }
        previewStage++;
        if (previewStage > 5) {
            previewStage = 3;
            previewFamily++;
            if (previewFamily > 4) { previewStage = 0; previewFamily = 0; }
        }
    }
}

class ArtPreviewInput extends TekuTekuBeastInput {
    function initialize(view) { TekuTekuBeastInput.initialize(view); }
    function onSelect() {
        (view.beast as ArtPreviewState).nextPreview();
        view.loadSprite();
        WatchUi.requestUpdate();
        return true;
    }
}

(:background)
class ArtPreviewApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() {
        var view = new TekuTekuBeastView();
        view.beast = new ArtPreviewState();
        return [view, new ArtPreviewInput(view)];
    }
}
