using Toybox.Application.Storage;
using Toybox.ActivityMonitor;
using Toybox.Time;
using Toybox.Time.Gregorian;

// Shared foreground/background model. All credit is from watch step totals.
(:background)
class StepPalState {
    function initialize() {}

    function number(key) {
        var x = Storage.getValue(key);
        return x == null ? 0 : x;
    }

    function dateKey(moment) {
        var d = Gregorian.info(moment, Time.FORMAT_SHORT);
        return d.year * 10000 + d.month * 100 + d.day;
    }

    function today() { return dateKey(Time.now()); }

    function start() {
        if (Storage.getValue("birth") != null) {
            if (Storage.getValue("birthEpoch") == null) {
                Storage.setValue("birthEpoch", Time.now().value());
            }
            return;
        }
        var info = ActivityMonitor.getInfo();
        var baseline = info.steps == null ? 0 : info.steps;
        Storage.setValue("birth", today());
        Storage.setValue("birthEpoch", Time.now().value());
        Storage.setValue("birthBaseline", baseline);
        Storage.setValue("xp", 0);
        Storage.setValue("snacks", 0);
        Storage.setValue("snackRemainder", 0);
        Storage.setValue("friendship", 0);
        Storage.setValue("schema", 1);
    }

    // Watermark each day; foreground and background can safely resync.
    function observe(day, total) {
        var born = number("birth");
        if (day < born || total < 0) { return; }

        var eligible = total;
        if (day == born) {
            eligible -= number("birthBaseline");
            if (eligible < 0) { eligible = 0; }
        }

        var slot = day % 32;
        var oldDay = Storage.getValue("day" + slot);
        var previous = (oldDay != null && oldDay == day)
            ? number("count" + slot) : 0;
        if (eligible <= previous) { return; }

        var delta = eligible - previous;
        Storage.setValue("day" + slot, day);
        Storage.setValue("count" + slot, eligible);
        Storage.setValue("xp", number("xp") + delta);

        var remaining = number("snackRemainder") + delta;
        var added = 0;
        while (remaining >= 2500) {
            remaining -= 2500;
            added++;
        }
        Storage.setValue("snackRemainder", remaining);
        var held = number("snacks") + added;
        Storage.setValue("snacks", held > 12 ? 12 : held);
    }

    function syncToday() {
        start();
        var info = ActivityMonitor.getInfo();
        if (info.steps != null) { observe(today(), info.steps); }
    }

    function syncHistory() {
        start();
        var history = ActivityMonitor.getHistory();
        for (var i = 0; i < history.size(); i++) {
            var item = history[i];
            if (item.startOfDay != null && item.steps != null) {
                observe(dateKey(item.startOfDay), item.steps);
            }
        }
        syncToday();
    }

    function xp() { return number("xp"); }

    function ageDays() {
        var born = Storage.getValue("birthEpoch");
        if (born == null) { return 0; }
        var seconds = Time.now().value() - born;
        if (seconds < 0) { return 0; }
        return (seconds / 86400).toNumber();
    }

    function stage() {
        var x = xp();
        var age = ageDays();
        if (x >= 300000 && age >= 21) { return 5; }
        if (x >= 150000 && age >= 14) { return 4; }
        if (x >= 70000 && age >= 7) { return 3; }
        if (x >= 20000 && age >= 2) { return 2; }
        if (x >= 2000) { return 1; }
        return 0;
    }

    function mastery() {
        if (stage() < 5) { return 0; }
        return 1 + ((xp() - 300000) / 25000).toNumber();
    }

    function masteryProgress() {
        if (stage() < 5) { return 0; }
        return (xp() - 300000) % 25000;
    }

    function nextSteps() {
        var s = stage();
        if (s == 0) { return 2000; }
        if (s == 1) { return 20000; }
        if (s == 2) { return 70000; }
        if (s == 3) { return 150000; }
        return 300000;
    }

    function nextAge() {
        var s = stage();
        if (s == 1) { return 2; }
        if (s == 2) { return 7; }
        if (s == 3) { return 14; }
        if (s == 4) { return 21; }
        return 0;
    }

    function family() {
        if (stage() < 3) { return 0; }
        var saved = number("family");
        if (saved != 0) { return saved; }

        var history = ActivityMonitor.getHistory();
        var big = 0;
        var steady = 0;
        var moderate = 0;
        var easy = 0;
        for (var i = 0; i < history.size(); i++) {
            var day = history[i];
            if (day.startOfDay == null || day.steps == null) { continue; }
            var key = dateKey(day.startOfDay);
            if (key < number("birth")) { continue; }
            var eligible = day.steps;
            if (key == number("birth")) {
                eligible -= number("birthBaseline");
                if (eligible < 0) { eligible = 0; }
            }
            if (eligible >= 18000) { big++; }
            if (eligible >= 6000) { steady++; }
            if (eligible >= 3000) { moderate++; }
            if (eligible < 3000) { easy++; }
        }
        var result = 4; // Wisp by default
        if (big >= 2) { result = 2; } // Ember
        else if (steady >= 5) { result = 1; } // Grove
        else if (moderate >= 3 && easy >= 1) { result = 3; } // Tide
        Storage.setValue("family", result);
        return result;
    }

    function familyName() {
        var f = family();
        if (f == 1) { return "GROVE"; }
        if (f == 2) { return "EMBER"; }
        if (f == 3) { return "TIDE"; }
        if (f == 4) { return "WISP"; }
        return "MYSTERY";
    }

    function speciesName() {
        var s = stage();
        if (s == 0) { return "MYSTERY EGG"; }
        if (s == 1) { return "PIP"; }
        if (s == 2) { return "NIMBLE"; }
        var f = family();
        if (s == 3) {
            if (f == 1) { return "MOSSBIT"; }
            if (f == 2) { return "CINDERCUB"; }
            if (f == 3) { return "PUDDLEFIN"; }
            return "FLICKLET";
        }
        if (s == 4) {
            if (f == 1) { return "THORNBUCK"; }
            if (f == 2) { return "PYROLYNX"; }
            if (f == 3) { return "CURRENTAIL"; }
            return "NOCTURNE";
        }
        if (f == 1) { return "VERDANT ELDER"; }
        if (f == 2) { return "SOLFLARE"; }
        if (f == 3) { return "LEVIATHAN"; }
        return "STARWEAVER";
    }

    function getTodaySteps() {
        var info = ActivityMonitor.getInfo();
        return info.steps == null ? 0 : info.steps;
    }

    function friendship() { return number("friendship"); }
    function snacks() { return number("snacks"); }

    function patsToday() {
        return Storage.getValue("patDay") == today() ? number("pats") : 0;
    }

    function pat() {
        var count = patsToday();
        if (count >= 3) { return false; }
        Storage.setValue("patDay", today());
        Storage.setValue("pats", count + 1);
        var bond = friendship() + 2;
        Storage.setValue("friendship", bond > 100 ? 100 : bond);
        return true;
    }

    function feed() {
        if (snacks() < 1) { return false; }
        Storage.setValue("snacks", snacks() - 1);
        var bond = friendship() + 5;
        Storage.setValue("friendship", bond > 100 ? 100 : bond);
        return true;
    }

    function mood() {
        if (getTodaySteps() >= 10000) { return "EXCITED"; }
        if (getTodaySteps() >= 3000) { return "PLAYFUL"; }
        if (friendship() >= 25) { return "CONTENT"; }
        return "COZY";
    }
}
