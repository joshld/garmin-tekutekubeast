using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;

// A separate application ID and an entirely in-memory model protect real saves.
class ArtPreviewState extends TekuTekuBeastState {
    var previewStage;
    var previewFamily;
    var stress;
    function initialize() {
        TekuTekuBeastState.initialize();
        previewStage = 0;
        previewFamily = 0;
        stress = 0;
    }
    function start() {}
    function syncToday() {}
    function syncHistory() {}
    function stage() { return previewStage; }
    function xp() {
        if (stress == 1) { return 2000000000; }
        if (stress == 2) { return 999999999; }
        if (previewStage == 0) { return 0; }
        if (previewStage == 1) { return 2500; }
        if (previewStage == 2) { return 25000; }
        if (previewStage == 3) { return 80000; }
        if (previewStage == 4) { return 170000; }
        return 325000;
    }
    function ageDays() { return stress > 0 ? 9999 : previewStage * 5; }
    function family() { return previewStage < 3 ? 0 : previewFamily; }
    function getTodaySteps() { return stress == 1 ? 1000000 : (stress == 2 ? 123456 : 12345); }
    function friendship() { return stress > 0 ? 100 : 60; }
    function snacks() { return stress > 0 ? 12 : 3; }
    function patsToday() { return stress > 0 ? 3 : 1; }
    function pat() { return true; }
    function feed() { return true; }
    function nextPreview() {
        if (stress == 1) { stress = 2; previewFamily = 4; return; }
        if (stress == 2) { stress = 0; previewStage = 0; previewFamily = 0; return; }
        // First three stages, followed by all twelve existing family-stage paths.
        if (previewStage < 2) { previewStage++; return; }
        if (previewStage == 2) { previewStage = 3; previewFamily = 1; return; }
        previewStage++;
        if (previewStage > 5) {
            previewStage = 3;
            previewFamily++;
            if (previewFamily > 4) { previewStage = 5; previewFamily = 1; stress = 1; }
        }
    }
}

class ArtLayoutAuditView extends TekuTekuBeastView {
    var auditBoxes as Lang.Array<Lang.Array>;
    var auditFailures as Lang.Array<Lang.String>;
    var audited;
    var showSummary;
    var scenes;

    function initialize() {
        TekuTekuBeastView.initialize();
        auditBoxes = [];
        auditFailures = [];
        audited = false;
        showSummary = true;
        scenes = 0;
    }

    function label(dc, y, value, font) {
        var box = TekuTekuBeastView.label(dc, y, value, font) as Lang.Array;
        auditBoxes.add(box);
        if (!audited && box[4] != value) {
            auditFailures.add("Truncated text: " + value);
        }
        return box;
    }

    function onShow() {
        TekuTekuBeastView.onShow();
        refresher.stop();
        refresher.start(method(:refresh), 200, true);
    }

    function checkScene(dc) {
        scenes++;
        var radius = dc.getWidth() / 2 - 8;
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        for (var i = 0; i < auditBoxes.size(); i++) {
            var box = auditBoxes[i];
            if (box[4] == "") { auditFailures.add("Empty label in scene " + scenes); }
            for (var corner = 0; corner < 4; corner++) {
                var x = box[0] + (corner % 2 == 0 ? 0 : box[2]);
                var y = box[1] + (corner < 2 ? 0 : box[3]);
                if ((x-cx)*(x-cx) + (y-cy)*(y-cy) > radius*radius) {
                    auditFailures.add("Outside circle: " + box[4]);
                }
            }
            for (var j = 0; j < i; j++) {
                var other = auditBoxes[j];
                if (box[0] < other[0]+other[2] && box[0]+box[2] > other[0]
                    && box[1] < other[1]+other[3] && box[1]+box[3] > other[1]) {
                    auditFailures.add("Overlapping rows: " + box[4]);
                }
            }
        }
    }

    function runAudit(dc) {
        // One scene per update avoids Garmin's per-callback watchdog.
        var model = beast as ArtPreviewState;
        if (scenes < 51) {
            page = scenes % 3;
            loadSprite();
            notice = null;
            auditBoxes = [];
            TekuTekuBeastView.onUpdate(dc);
            checkScene(dc);
            if (page == 2) { model.nextPreview(); }
        } else if (scenes < 55) {
            var notices = ["HAPPY BEAST!", "PATS: 3/3", "BOND +5", "NO SNACKS YET"] as Lang.Array<Lang.String>;
            var n = scenes - 51;
            page = n < 2 ? 0 : 1;
            notice = notices[n];
            auditBoxes = [];
            TekuTekuBeastView.onUpdate(dc);
            checkScene(dc);
        }
        if (scenes < 55) { return; }
        notice = null;
        page = 0;
        loadSprite();
        audited = true;
        refresher.stop();
        refresher.start(method(:refresh), 1000, true);
        System.println("LAYOUT_AUDIT: " + scenes + " scenes; " + auditFailures.size() + " failures");
        for (var error = 0; error < auditFailures.size(); error++) {
            System.println(auditFailures[error]);
        }
        System.println("FONT_HEIGHTS: " + dc.getFontHeight(Graphics.FONT_XTINY) + ", "
            + dc.getFontHeight(Graphics.FONT_SMALL) + ", " + dc.getFontHeight(Graphics.FONT_LARGE));
    }

    function onUpdate(dc) {
        if (!audited) {
            runAudit(dc);
            if (!audited) { return; }
        }
        if (showSummary) {
            auditBoxes = [];
            dc.setColor(BG, BG);
            dc.clear();
            label(dc, 56, "ROUND LAYOUT AUDIT", Graphics.FONT_XTINY);
            label(dc, 100, auditFailures.size() == 0 ? "PASS" : "FAIL", Graphics.FONT_LARGE);
            label(dc, 157, scenes.toString() + " SCENES CHECKED", Graphics.FONT_XTINY);
            label(dc, 187, auditFailures.size().toString() + " OVERLAPS / CLIPS", Graphics.FONT_XTINY);
            label(dc, 220, "SELECT: PREVIEW", Graphics.FONT_XTINY);
        } else {
            auditBoxes = [];
            TekuTekuBeastView.onUpdate(dc);
        }
    }
}

class ArtPreviewInput extends TekuTekuBeastInput {
    function initialize(view) { TekuTekuBeastInput.initialize(view); }
    function onSelect() {
        var preview = view as ArtLayoutAuditView;
        if (!preview.audited) { return true; }
        if (preview.showSummary) {
            preview.showSummary = false;
        } else {
            (view.beast as ArtPreviewState).nextPreview();
        }
        view.loadSprite();
        WatchUi.requestUpdate();
        return true;
    }
}

(:background)
class ArtPreviewApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() {
        var view = new ArtLayoutAuditView();
        view.beast = new ArtPreviewState();
        return [view, new ArtPreviewInput(view)];
    }
}
