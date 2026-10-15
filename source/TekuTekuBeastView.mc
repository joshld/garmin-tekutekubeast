using Toybox.Graphics;
using Toybox.Timer;
using Toybox.WatchUi;
using Toybox.Lang;

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
            notice = beast.pat() ? "HAPPY BEAST!" : "PATS: 3 / 3 TODAY";
        }
        if (page == 1) {
            notice = beast.feed() ? "YUM! +5 FRIENDSHIP" : "WALK TO EARN SNACKS";
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

    function label(dc, y, value, font) {
        // Long species labels use the smaller built-in face, inside the circle.
        if (dc.getTextWidthInPixels(value, font) > 218) {
            font = Graphics.FONT_XTINY;
        }
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
            dc.drawBitmap(84, 91 - lift, sprite);
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
            pixelIcon(dc, 89 + i * 20, 78, heart, color, 2);
        }
        var snack = [8, 28, 62, 127, 65, 127];
        pixelIcon(dc, 160, 78, snack, INK, 2);
        dc.drawText(180, 73, Graphics.FONT_XTINY,
            beast.snacks().toString(), Graphics.TEXT_JUSTIFY_LEFT);
    }

    function pageDots(dc) {
        for (var i = 0; i < 3; i++) {
            dc.setColor(i == page ? INK : LIGHT, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(126 + i * 14, 265, 3);
        }
    }

    // Temporary higher-stage drawing, retained until family sprite work lands.
    function legacyCreature(dc) {
        var stage = beast.stage();
        var cx = dc.getWidth() / 2;
        var cy = 147;
        var size = 25 + stage * 4;
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
        label(dc, 23, "TEKUTEKU BEAST", Graphics.FONT_XTINY);
        label(dc, 44, beast.speciesName(), Graphics.FONT_SMALL);
        statusIcons(dc);
        creature(dc);
        dc.setColor(LIGHT, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(88, 202, 104, 2);

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
        var width = ((progress * 146) / maximum).toNumber();
        dc.setColor(LIGHT, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(66, 210, 148, 8);
        dc.setColor(INK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(67, 211, width, 6);

        if (beast.stage() == 5) {
            label(dc, 220, "MASTERY LV " + beast.mastery().toString(),
                Graphics.FONT_XTINY);
        } else if (remaining <= 0 && beast.ageDays() < beast.nextAge()) {
            var left = beast.nextAge() - beast.ageDays();
            label(dc, 220, "READY IN " + left.toString() + " DAYS",
                Graphics.FONT_XTINY);
        } else {
            var leftSteps = remaining > 0 ? remaining : 0;
            label(dc, 220, leftSteps.toString() + " TO NEXT",
                Graphics.FONT_XTINY);
        }
        var footer = notice != null ? notice : "TODAY " + beast.getTodaySteps().toString();
        label(dc, 237, footer,
            Graphics.FONT_XTINY);
        pageDots(dc);
    }

    function drawCare(dc) {
        label(dc, 28, "CARE", Graphics.FONT_SMALL);
        label(dc, 65, beast.mood(), Graphics.FONT_XTINY);
        label(dc, 94, "SNACKS", Graphics.FONT_XTINY);
        label(dc, 114, beast.snacks().toString() + " / 12",
            Graphics.FONT_LARGE);
        label(dc, 158, "FRIENDSHIP " + beast.friendship().toString()
            + "/100", Graphics.FONT_XTINY);
        dc.setColor(LIGHT, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(66, 184, 148, 8);
        dc.setColor(INK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(67, 185, (beast.friendship() * 146 / 100).toNumber(), 6);
        label(dc, 202, "1 SNACK / 2500 STEPS", Graphics.FONT_XTINY);
        label(dc, 230, notice != null ? notice : "SELECT: FEED", Graphics.FONT_XTINY);
        pageDots(dc);
    }

    function drawStats(dc) {
        label(dc, 26, "YOUR BEAST", Graphics.FONT_XTINY);
        label(dc, 54, beast.speciesName(), Graphics.FONT_SMALL);
        label(dc, 86, stageLabel(), Graphics.FONT_XTINY);
        if (beast.stage() >= 3) {
            label(dc, 109, "FAMILY: " + beast.familyName(),
                Graphics.FONT_XTINY);
        } else {
            label(dc, 109, "FAMILY: UNDISCOVERED", Graphics.FONT_XTINY);
        }
        label(dc, 143, "CREDITED WATCH STEPS", Graphics.FONT_XTINY);
        label(dc, 163, beast.xp().toString(), Graphics.FONT_LARGE);
        label(dc, 207, "AGE " + beast.ageDays().toString() + " DAYS",
            Graphics.FONT_XTINY);
        if (beast.stage() == 5) {
            label(dc, 229, "MASTERY " + beast.mastery().toString(),
                Graphics.FONT_XTINY);
        } else {
            label(dc, 229, "PATS TODAY " + beast.patsToday().toString()
                + "/3", Graphics.FONT_XTINY);
        }
        pageDots(dc);
    }
}
