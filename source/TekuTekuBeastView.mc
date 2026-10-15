using Toybox.Graphics;
using Toybox.Timer;
using Toybox.WatchUi;

class TekuTekuBeastView extends WatchUi.View {
    var beast;
    var page; // 0 = Pet, 1 = Care, 2 = Stats
    var refresher;

    const BG = 0xD7E6BC;
    const INK = 0x283D2F;
    const LIGHT = 0xA8C795;
    const GROVE = 0x619348;
    const EMBER = 0xC86632;
    const TIDE = 0x418CA6;
    const WISP = 0x966AAB;

    function initialize() {
        View.initialize();
        beast = new TekuTekuBeastState();
        page = 0;
        refresher = null;
    }

    function onShow() {
        beast.syncHistory();
        refresher = new Timer.Timer();
        refresher.start(method(:refresh), 20000, true);
    }

    function onHide() {
        if (refresher != null) {
            refresher.stop();
            refresher = null;
        }
    }

    function refresh() as Void {
        beast.syncToday();
        WatchUi.requestUpdate();
    }

    function selectAction() {
        if (page == 0) { beast.pat(); }
        if (page == 1) { beast.feed(); }
        WatchUi.requestUpdate();
    }

    function switchPage(delta) {
        page = (page + delta + 3) % 3;
        WatchUi.requestUpdate();
    }

    function label(dc, y, value, font) {
        dc.setColor(INK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, y, font, value,
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    function familyColor(f) {
        if (f == 1) { return GROVE; }
        if (f == 2) { return EMBER; }
        if (f == 3) { return TIDE; }
        if (f == 4) { return WISP; }
        return GROVE;
    }

    // Native primitive placeholder sprite until final pixel art is created.
    function creature(dc) {
        var stage = beast.stage();
        var cx = dc.getWidth() / 2;
        var cy = 138;
        var size = 27 + stage * 6;
        var color = familyColor(beast.family());
        dc.setColor(INK, Graphics.COLOR_TRANSPARENT);
        if (stage == 0) {
            dc.fillEllipse(cx, cy, 35, 45);
            dc.setColor(BG, Graphics.COLOR_TRANSPARENT);
            dc.fillEllipse(cx, cy, 31, 41);
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.fillEllipse(cx, cy + 10, 18, 18);
            return;
        }

        // Ears or horns differ by lineage; rounded body and large eyes.
        if (stage >= 3) {
            if (beast.family() == 1) {
                dc.fillRectangle(cx - size, cy - size - 10, 14, 34);
                dc.fillRectangle(cx + size - 14, cy - size - 10, 14, 34);
            } else if (beast.family() == 2) {
                dc.fillRectangle(cx - size + 3, cy - size - 16, 14, 36);
                dc.fillRectangle(cx + size - 17, cy - size - 16, 14, 36);
            } else if (beast.family() == 3) {
                dc.fillCircle(cx - size + 2, cy, 15);
                dc.fillCircle(cx + size - 2, cy, 15);
            } else {
                dc.fillCircle(cx, cy - size + 3, 17);
            }
        } else {
            dc.fillCircle(cx - size + 3, cy - size + 12, 13);
            dc.fillCircle(cx + size - 3, cy - size + 12, 13);
        }

        dc.setColor(INK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, size + 3);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, size);
        dc.setColor(INK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - 15, cy - 6, 5);
        dc.fillCircle(cx + 15, cy - 6, 5);
        dc.fillRectangle(cx - 8, cy + 15, 16, 3);
        dc.fillRectangle(cx - size + 8, cy + size - 1, 12, 8);
        dc.fillRectangle(cx + size - 20, cy + size - 1, 12, 8);
    }

    function onUpdate(dc) {
        dc.setColor(BG, BG);
        dc.clear();
        if (page == 0) { drawPet(dc); }
        else if (page == 1) { drawCare(dc); }
        else { drawStats(dc); }
    }

    function stageLabel() {
        var s = beast.stage();
        if (s == 0) { return "EGG"; }
        if (s == 1) { return "HATCHLING"; }
        if (s == 2) { return "JUVENILE"; }
        if (s == 3) { return "ADULT"; }
        if (s == 4) { return "CHAMPION"; }
        return "LEGENDARY";
    }

    function drawPet(dc) {
        label(dc, 19, "TEKUTEKU BEAST", Graphics.FONT_SMALL);
        label(dc, 51, beast.speciesName(), Graphics.FONT_SMALL);
        creature(dc);
        label(dc, 185, beast.mood(), Graphics.FONT_SMALL);

        var remaining = beast.nextSteps() - beast.xp();
        var progress = 0;
        var maximum = beast.nextSteps();
        if (beast.stage() == 5) {
            progress = beast.masteryProgress();
            maximum = 25000;
        } else {
            var previous = 0;
            if (beast.stage() == 1) { previous = 2000; }
            if (beast.stage() == 2) { previous = 20000; }
            if (beast.stage() == 3) { previous = 70000; }
            if (beast.stage() == 4) { previous = 150000; }
            progress = beast.xp() - previous;
            maximum -= previous;
        }
        if (progress < 0) { progress = 0; }
        if (progress > maximum) { progress = maximum; }
        var width = ((progress * 124) / maximum).toNumber();
        dc.setColor(LIGHT, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(77, 217, 126, 9);
        dc.setColor(INK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(78, 218, width, 7);

        if (beast.stage() == 5) {
            label(dc, 232, "MASTERY LV " + beast.mastery().toString(),
                Graphics.FONT_XTINY);
        } else if (remaining <= 0 && beast.ageDays() < beast.nextAge()) {
            var left = beast.nextAge() - beast.ageDays();
            label(dc, 232, "READY IN " + left.toString() + " DAYS",
                Graphics.FONT_XTINY);
        } else {
            var leftSteps = remaining > 0 ? remaining : 0;
            label(dc, 232, leftSteps.toString() + " STEPS TO NEXT",
                Graphics.FONT_XTINY);
        }
        label(dc, 251, "TODAY " + beast.getTodaySteps().toString(),
            Graphics.FONT_XTINY);
        label(dc, 265, "SELECT: PAT", Graphics.FONT_XTINY);
    }

    function drawCare(dc) {
        label(dc, 25, "CARE", Graphics.FONT_LARGE);
        label(dc, 78, "MOOD: " + beast.mood(), Graphics.FONT_SMALL);
        label(dc, 118, "SNACKS", Graphics.FONT_SMALL);
        label(dc, 147, beast.snacks().toString() + " / 12",
            Graphics.FONT_LARGE);
        label(dc, 196, "FRIENDSHIP " + beast.friendship().toString()
            + "/100", Graphics.FONT_SMALL);
        label(dc, 229, "1 SNACK / 2500 STEPS", Graphics.FONT_XTINY);
        label(dc, 252, "SELECT: FEED", Graphics.FONT_SMALL);
    }

    function drawStats(dc) {
        label(dc, 24, "BEAST STATS", Graphics.FONT_SMALL);
        label(dc, 67, "STAGE: " + stageLabel(), Graphics.FONT_SMALL);
        if (beast.stage() >= 3) {
            label(dc, 91, "FAMILY: " + beast.familyName(),
                Graphics.FONT_SMALL);
        }
        label(dc, 124, "CREDITED WATCH STEPS", Graphics.FONT_XTINY);
        label(dc, 149, beast.xp().toString(), Graphics.FONT_LARGE);
        label(dc, 192, "AGE " + beast.ageDays().toString() + " DAYS",
            Graphics.FONT_SMALL);
        if (beast.stage() == 5) {
            label(dc, 216, "MASTERY " + beast.mastery().toString(),
                Graphics.FONT_SMALL);
        }
        label(dc, 241, "PATS TODAY " + beast.patsToday().toString()
            + "/3", Graphics.FONT_SMALL);
        label(dc, 259, "UP/DOWN: NAVIGATE", Graphics.FONT_XTINY);
    }
}
