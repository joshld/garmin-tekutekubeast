using Toybox.Test;
using Toybox.System;
using Toybox.Timer;
using Toybox.WatchUi;
using Toybox.Graphics;

// Isolated QA identity and RAM store. No production pet or Garmin steps changed.
class ReleaseFixture extends TekuTekuBeastState {
    var clock=1792108800l;
    function initialize(){TekuTekuBeastState.initialize();store.memory={};skipWatch=true;start();}
    function realNow(){return clock;}
}
(:test)
function publicBattleSaveAndClaimTest(logger){
    var s=new ReleaseFixture();s.data["sleepMode"]=2;s.data["stageFloor"]=1;s.commit();
    var before=s.store.copy(s.store.read("v4"));var fight=new BeastBattle(s);fight.beginBattle();
    fight.data["active"]["actors"][1]["hp"]=1;fight.battleTurn(0);fight.finishBattle();
    Test.assertEqual(fight.battleXp(),12);Test.assert(s.store.same(before,s.store.read("v4")));
    s.battleData=null;var reload=new BeastBattle(s);reload.finishBattle();Test.assertEqual(reload.battleXp(),12);
    Test.assert(!(s has :enableDev));return true;
}
(:test)
function publicToolsAbsentTest(logger){
    var s=new ReleaseFixture();
    Test.assert(!(s has :enableDev));Test.assert(!(s has :devSet));
    Test.assert(!(s has :setSpeed));Test.assert(!(s has :jump));
    Test.assert(!(s has :simulateSleep));Test.assert(!s.dev);
    var v=new TekuTekuBeastView();v.beast=s;v.openMenu("Settings");
    Test.assertEqual(v.rows.size(),9);Test.assert(v.rows[0].find("Sound:")==0);
    var before=s.number("sound");v.selectAction();Test.assertEqual(s.number("sound"),1-before);
    v.openMenu("Settings");v.selection=8;v.selectAction();Test.assertEqual(v.menu,"Outdoor world");
    Test.assertEqual(v.rows.size(),2);return true;
}
(:test)
function publicUpgradeAndCatchupTest(logger){
    var s=new ReleaseFixture();s.observe(s.today(),6000);s.data["friendship"]=73;
    s.data["items"][7]=9;s.data["collection"]=15;s.data["rareCollection"]=3;
    var session=s.beginSession(1);s.commit();var saved=s.store.copy(s.data);
    var reload=new ReleaseFixture();reload.store=s.store;reload.data=null;reload.start();
    Test.assert(reload.store.same(reload.data,saved));Test.assertEqual(reload.xp(),6000l);
    reload.observe(reload.today(),6000);Test.assertEqual(reload.xp(),6000l);
    reload.clock+=26*86400;reload.syncHistory();Test.assertEqual(reload.stage(),5);
    Test.assertEqual(reload.xp(),6000l);Test.assertEqual(reload.friendship(),73);
    Test.assertEqual(reload.data["items"][7],9);Test.assertEqual(reload.number("collection"),15);
    Test.assertEqual(reload.data["sessions"][1]["id"],session["id"]);
    Test.assertEqual(reload.number("evolutionPending"),1);
    reload.data["evolutionPending"]=0;reload.commit();var writes=reload.store.writes;
    reload.commit();Test.assertEqual(reload.store.writes,writes);
    Test.assertEqual(reload.store.read("glance.v1")["cachedName"],reload.speciesName());return true;
}
(:test)
function publicV4AdditiveMigrationTest(logger){
    var s=new ReleaseFixture();s.data["xp"]=54321l;s.data["snacks"]=6;
    s.data["friendship"]=82;s.data["family"]=2;s.data["stageFloor"]=3;
    s.data["days"][0]=20261015;s.data["counts"][0]=7200;
    s.data.remove("sleepMode");s.data.remove("sessions");s.data.remove("gameClaims");
    s.store.write("v4",s.store.copy(s.data));s.data=null;s.start();
    Test.assertEqual(s.xp(),54321l);Test.assertEqual(s.snacks(),6);
    Test.assertEqual(s.friendship(),82);Test.assertEqual(s.stage(),3);
    Test.assertEqual(s.family(),2);Test.assertEqual(s.data["counts"][0],7200);
    Test.assertEqual(s.data["sessions"].size(),3);return true;
}
(:test)
function publicGameRecoveryAndCareTest(logger){
    var s=new ReleaseFixture();s.data["adventure"]=2;s.commit();
    var a=s.beginSession(2);Test.assertEqual(s.number("adventure"),1);
    Test.assertEqual(s.beginSession(2)["id"],a["id"]);Test.assertEqual(s.number("adventure"),1);
    s.completeSession(a,true);var itemCount=s.number("encounters");s.completeSession(a,true);
    Test.assertEqual(s.number("encounters"),itemCount);
    s.data["fullness"]=40;Test.assert(s.feedFood(true));Test.assert(s.number("poopDue")>s.now());
    s.clock+=10801;s.tick();Test.assert(s.number("poop")>0);Test.assert(s.clean());
    Test.assertEqual(s.number("poop"),0);Test.assertEqual(s.xp(),0l);return true;
}
class ReleaseAudit extends TekuTekuBeastView {
    var scene=0;var errors=0;var pump;var memoryPeak=0;
    function initialize(){TekuTekuBeastView.initialize();beast=new ReleaseFixture();}
    function onShow(){pump=new Timer.Timer();pump.start(method(:next),40,true);}
    function onHide(){if(pump!=null){pump.stop();}TekuTekuBeastView.onHide();}
    function next() as Void {WatchUi.requestUpdate();}
    function label(dc,top,value,font){
        var box=TekuTekuBeastView.label(dc,top,value,font);
        if(!box[4].equals(value)){errors++;System.println("PUBLIC_LAYOUT_ERROR: "+value);}
        return box;
    }
    function onUpdate(dc){
        var menus=["Settings","Actions","Outdoor world","Feed","Bedtime","Feedback test","Play"];
        if(scene<menus.size()*3){openMenu(menus[(scene/3).toNumber()]);selection=scene%3;if(selection>=rows.size()){selection=rows.size()-1;}}
        else{menu=null;page=(scene-menus.size()*3)%3;beast.data["stageFloor"]=(scene/3).toNumber()%6;beast.data["family"]=1+scene%4;loadSprite();}
        TekuTekuBeastView.onUpdate(dc);scene++;
        var stats=System.getSystemStats();memoryPeak=beast.max(memoryPeak,stats.usedMemory);
        if(scene==57){pump.stop();System.println("PUBLIC_LAYOUT: 57 scenes; failures="+errors+" peak="+memoryPeak+" total="+stats.totalMemory);System.exit();}
    }
}
(:background,:glance)
class PublicReleaseQA extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){var v=new ReleaseAudit();return [v,new TekuTekuBeastInput(v)];}
}
