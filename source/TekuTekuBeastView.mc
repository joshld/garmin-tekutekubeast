using Toybox.Graphics;
using Toybox.Timer;
using Toybox.WatchUi;
using Toybox.Lang;
using Toybox.Math;

class TekuTekuBeastView extends WatchUi.View {
    var beast;
    var page; // 0 = Pet, 1 = Care, 2 = Stats
    var refresher;
    var sprite;
    var spriteStage;
    var tick;
    var notice;
    var noticeTicks;

    // Exact Enduro 4 MIP palette colors; no dithering on the pixel art.
    const BG = 0xAAFFAA;
    const INK = 0x005500;
    const LIGHT = 0x55AA55;
    const GROVE = 0x619348;
    const EMBER = 0xC86632;
    const TIDE = 0x418CA6;
    const WISP = 0x966AAB;

    function initialize() {
        View.initialize();
        beast = new TekuTekuBeastState();
        page = 0;
        refresher = null;
        sprite = null;
        spriteStage = -1;
        tick = 0;
        notice = null;
        noticeTicks = 0;
    }

    function onShow() {
        beast.syncHistory();
        loadSprite();
        refresher = new Timer.Timer();
        // Gentle foreground-only idle movement; step reconciliation stays 20s.
        refresher.start(method(:refresh), 1000, true);
    }

    function onHide() {
        if (refresher != null) {
            refresher.stop();
            refresher = null;
        }
    }

    function refresh() as Void {
        tick = (tick + 1) % 20;
        if (tick == 0) {
            beast.syncToday();
            loadSprite();
        }
        if (noticeTicks > 0) {
            noticeTicks--;
            if (noticeTicks == 0) { notice = null; }
        }
        WatchUi.requestUpdate();
    }

    function selectAction() {
        if (page == 0) {
            notice = beast.pat() ? "HAPPY BEAST!" : "PATS: 3/3";
        }
        if (page == 1) {
            notice = beast.feed() ? "BOND +5" : "NO SNACKS YET";
        }
        noticeTicks = 4;
        WatchUi.requestUpdate();
    }

    function switchPage(delta) {
        page = (page + delta + 3) % 3;
        notice = null;
        noticeTicks = 0;
        WatchUi.requestUpdate();
    }

    function safeTextWidth(dc, y, font) {
        // Fit the whole font box, not just its baseline, inside an inset circle.
        var radius = dc.getWidth() / 2 - 8;
        var centerY = dc.getHeight() / 2;
        var top = y - centerY;
        if (top < 0) { top = -top; }
        var bottom = y + dc.getFontHeight(font) - centerY;
        if (bottom < 0) { bottom = -bottom; }
        var distance = top > bottom ? top : bottom;
        if (distance >= radius) { return 0; }
        return (2 * Math.sqrt(radius * radius - distance * distance)).toNumber() - 4;
    }

    function label(dc, y, value, font) {
        var available = safeTextWidth(dc, y, font);
        if (dc.getTextWidthInPixels(value, font) > available && font == Graphics.FONT_LARGE) {
            font = Graphics.FONT_SMALL;
            available = safeTextWidth(dc, y, font);
        }
        if (dc.getTextWidthInPixels(value, font) > available && font != Graphics.FONT_XTINY) {
            font = Graphics.FONT_XTINY;
            available = safeTextWidth(dc, y, font);
        }
        // Last resort for future longer translations/species, never crop glyphs.
        var shown = value;
        while (shown.length() > 0 && dc.getTextWidthInPixels(shown, font) > available) {
            var keep = shown.length() - 1;
            if (shown.length() >= 3 && shown.substring(shown.length() - 3, shown.length()) == "...") {
                keep = shown.length() - 4;
            }
            shown = keep > 0 ? value.substring(0, keep) + "..." : "";
        }
        dc.setColor(INK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, y, font, shown,
            Graphics.TEXT_JUSTIFY_CENTER);
        var width = dc.getTextWidthInPixels(shown, font);
        // The isolated visual test checks these exact native-font bounds.
        return [dc.getWidth() / 2 - width / 2, y, width, dc.getFontHeight(font), shown];
    }

    function todayLabel() {
        var steps = beast.getTodaySteps();
        if (steps >= 1000000) {
            return "TODAY " + (steps / 1000000.0).format("%.1f") + "M";
        }
        if (steps >= 100000) {
            return "TODAY " + (steps / 1000).toString() + "K";
        }
        return "TODAY " + steps.toString();
    }

    function familyColor(f) {
        if (f == 1) { return GROVE; }
        if (f == 2) { return EMBER; }
        if (f == 3) { return TIDE; }
        if (f == 4) { return WISP; }
        return GROVE;
    }

    function loadSprite() {
        var stage = beast.stage();
        if (stage == spriteStage) { return; }
        spriteStage = stage;
        sprite = null;
        if (stage == 0) { sprite = WatchUi.loadResource(Rez.Drawables.Egg); }
        else if (stage == 1) { sprite = WatchUi.loadResource(Rez.Drawables.Pip); }
        else if (stage == 2) { sprite = WatchUi.loadResource(Rez.Drawables.Nimble); }
    }

    function creature(dc) {
        if (sprite != null) {
            var lift = tick % 4 == 1 ? 2 : 0;
            dc.drawBitmap(84, 104 - lift, sprite);
            return;
        }
        // Adult/family artwork is a separate pass; keep all existing saves usable.
        legacyCreature(dc);
    }

    function pixelIcon(dc, x, y, rows as Lang.Array<Lang.Number>, color, scale) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        for (var row = 0; row < rows.size(); row++) {
            for (var col = 0; col < 7; col++) {
                if ((rows[row] & (1 << (6 - col))) != 0) {
                    dc.fillRectangle(x + col * scale, y + row * scale, scale, scale);
                }
            }
        }
    }

    function statusIcons(dc) {
        var heart = [54, 127, 127, 62, 28, 8];
        for (var i = 0; i < 3; i++) {
            var color = beast.friendship() > i * 34 ? INK : LIGHT;
            pixelIcon(dc, 89 + i * 20, 90, heart, color, 2);
        }
        var snack = [8, 28, 62, 127, 65, 127];
        pixelIcon(dc, 160, 90, snack, INK, 2);
        dc.drawText(180, 80, Graphics.FONT_XTINY,
            beast.snacks().toString(), Graphics.TEXT_JUSTIFY_LEFT);
    }

    function pageDots(dc) {
        for (var i = 0; i < 3; i++) {
            dc.setColor(i == page ? INK : LIGHT, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(126 + i * 14, 258, 3);
        }
    }

    // Temporary higher-stage drawing, retained until family sprite work lands.
    function legacyCreature(dc) {
        var stage = beast.stage();
        var cx = dc.getWidth() / 2;
        var cy = 163;
        var size = 23 + stage * 4;
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
        label(dc, 30, "TEKUTEKU BEAST", Graphics.FONT_XTINY);
        label(dc, 54, beast.speciesName(), Graphics.FONT_SMALL);
        statusIcons(dc);
        creature(dc);
        dc.setColor(LIGHT, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(88, 214, 104, 2);

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
        var width = ((progress * 146) / maximum).toNumber();
        dc.setColor(LIGHT, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(66, 217, 148, 8);
        dc.setColor(INK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(67, 218, width, 6);

        // Keep one bottom text row. Exact evolution details live on Your Beast.
        var footer = notice != null ? notice : todayLabel();
        label(dc, 228, footer,
            Graphics.FONT_XTINY);
        pageDots(dc);
    }

    function drawCare(dc) {
        label(dc, 30, "CARE", Graphics.FONT_SMALL);
        label(dc, 65, beast.mood(), Graphics.FONT_XTINY);
        label(dc, 94, "SNACKS", Graphics.FONT_XTINY);
        label(dc, 119, beast.snacks().toString() + " / 12",
            Graphics.FONT_LARGE);
        label(dc, 165, "FRIENDSHIP " + beast.friendship().toString()
            + "/100", Graphics.FONT_XTINY);
        dc.setColor(LIGHT, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(66, 193, 148, 8);
        dc.setColor(INK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(67, 194, (beast.friendship() * 146 / 100).toNumber(), 6);
        label(dc, 205, "1 SNACK / 2500 STEPS", Graphics.FONT_XTINY);
        label(dc, 231, notice != null ? notice : "SELECT: FEED", Graphics.FONT_XTINY);
        pageDots(dc);
    }

    function drawStats(dc) {
        label(dc, 30, "YOUR BEAST", Graphics.FONT_XTINY);
        label(dc, 55, beast.speciesName(), Graphics.FONT_SMALL);
        var stage = stageLabel();
        if (beast.stage() >= 3) {
            stage += " / " + beast.familyName();
        }
        label(dc, 92, stage, Graphics.FONT_XTINY);
        label(dc, 116, "TOTAL STEP XP", Graphics.FONT_XTINY);
        label(dc, 140, beast.xp().toString(), Graphics.FONT_LARGE);
        if (beast.stage() == 5) {
            label(dc, 188, "MASTERY " + beast.mastery().toString(),
                Graphics.FONT_XTINY);
        } else {
            var remaining = beast.nextSteps() - beast.xp();
            if (remaining <= 0 && beast.ageDays() < beast.nextAge()) {
                var days = beast.nextAge() - beast.ageDays();
                label(dc, 188, "READY IN " + days.toString() + " DAYS", Graphics.FONT_XTINY);
            } else {
                label(dc, 188, (remaining > 0 ? remaining : 0).toString() + " XP TO NEXT", Graphics.FONT_XTINY);
            }
        }
        label(dc, 214, "DAY " + beast.ageDays().toString() + " | PATS "
            + beast.patsToday().toString() + "/3", Graphics.FONT_XTINY);
        pageDots(dc);
    }
}
