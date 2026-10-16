using Toybox.Test;
using Toybox.Lang;

(:test)
module TestSupport {
    function fixture(){
        var s=new TekuTekuBeastState();s.store.memory={};s.skipWatch=true;s.testNow=1792108800l;s.start();return s;
    }
}
(:test)
function migrationTest(logger){
    var s=new TekuTekuBeastState();s.store.memory={"birth"=>20261015,"birthEpoch"=>1792022400l,"birthBaseline"=>100,
        "xp"=>5974,"snacks"=>2,"friendship"=>6,"patDay"=>20261015,"pats"=>3,"day15"=>20261015,"count15"=>5974};
    s.skipWatch=true;s.testNow=1792108800l;s.start();
    Test.assertEqual(s.xp(),5974l);Test.assertEqual(s.stage(),1);Test.assertEqual(s.friendship(),6);Test.assertEqual(s.snacks(),2);
    Test.assertEqual(s.store.read("xp"),5974);s.commit();var again=new TekuTekuBeastState();again.store=s.store;again.skipWatch=true;again.testNow=s.testNow;again.start();
    Test.assertEqual(again.xp(),5974l);Test.assertEqual(again.stage(),1);return true;
}
(:test)
function devIsolationTest(logger){
    var s=TestSupport.fixture();s.observe(s.today(),3000);s.commit();var d=s.enableDev();
    d.jump(604800);d.devSet("forcedStage",5);d.devSet("friendship",100);d.devSet("snacks",12);d.pat();d.commit();
    Test.assertEqual(s.store.read("v4")["xp"],3000l);Test.assertEqual(s.store.read("v4")["friendship"],0);
    d.observe(s.today(),999999);Test.assertEqual(d.xp(),3000l);
    var restored=new TekuTekuBeastState();restored.store=s.store;restored.testNow=s.testNow;restored.skipWatch=true;restored.start();
    restored.observe(s.today(),4500);restored.commit();Test.assertEqual(restored.xp(),4500l);Test.assertEqual(restored.stage(),0);return true;
}
(:test)
function passiveGrowthTest(logger){
    var s=TestSupport.fixture();s.testNow+=7*86400;s.tick();Test.assertEqual(s.growth(),84000l);Test.assertEqual(s.stage(),3);
    s.testNow+=18*86400;s.tick();Test.assertEqual(s.growth(),300000l);Test.assertEqual(s.stage(),5);Test.assertEqual(s.xp(),0l);
    s.testNow+=75*86400;s.tick();Test.assertEqual(s.growth(),1200000l);Test.assert(s.mastery()>1);
    var g=s.growth();s.tick();Test.assertEqual(s.growth(),g);s.testNow-=86400;s.tick();Test.assertEqual(s.growth(),g);return true;
}
(:test)
function hatchTest(logger){
    var s=TestSupport.fixture();s.observe(s.today(),20000);s.testNow+=7*3600;s.tick();Test.assertEqual(s.stage(),0);
    s.testNow+=3600;s.tick();Test.assertEqual(s.stage(),1);
    var z=TestSupport.fixture();z.testNow+=23*3600;z.tick();Test.assertEqual(z.stage(),0);z.testNow+=3600;z.tick();Test.assertEqual(z.stage(),1);return true;
}
(:test)
function careAndRewardTest(logger){
    var s=TestSupport.fixture();Test.assert(s.feedFood(true));Test.assertEqual(s.number("meals"),1);Test.assertEqual(s.xp(),0l);
    s.testNow+=4*3600;s.tick();Test.assertEqual(s.number("poop"),1);Test.assert(s.clean());Test.assert(!s.clean());
    s.testNow+=86400;s.tick();Test.assertEqual(s.number("meals"),2);s.feedFood(true);var meals=s.number("meals");
    s.testNow-=86400;s.tick();Test.assertEqual(s.number("meals"),meals);
    for(var i=0;i<8;i++){s.gameReward(true,i%2);}Test.assertEqual(s.number("games"),3);Test.assertEqual(s.xp(),0l);return true;
}
(:test)
function stepsAndAlternativesTest(logger){
    var s=TestSupport.fixture();var day=s.today();s.observe(day,5000);s.observe(day,5000);s.observe(day,4000);Test.assertEqual(s.xp(),5000l);Test.assertEqual(s.snacks(),2);
    s.activityRewards(day,5000,0,0);s.activityRewards(day,5000,20,1000);s.activityRewards(day,5000,20,1000);Test.assertEqual(s.number("adventure"),2);
    var z=TestSupport.fixture();z.careReward(300,3);Test.assertEqual(z.number("adventure"),3);
    for(var i=0;i<8;i++){z.data["adventure"]++;z.explore(0);}for(var i=0;i<8;i++){Test.assert(z.data["items"][i]>0);}Test.assertEqual(z.xp(),0l);return true;
}
(:test)
function familiesTest(logger){
    for(var f=0;f<4;f++){var s=TestSupport.fixture();s.data["personality"][f]=20;s.testNow+=25*86400;s.tick();Test.assertEqual(s.family(),f+1);
        s.data["friendship"]=70;Test.assert(s.rareEvolve());Test.assertEqual(s.number("rare"),1);Test.assertEqual(s.xp(),0l);}
    return true;
}
(:test)
function navigationAndDevTest(logger){
    var v=new TekuTekuBeastView();v.beast=TestSupport.fixture();v.selectAction();
    Test.assertEqual(v.rows.size(),7);v.selection=6;v.selectAction();Test.assert(v.menu.equals("Settings"));
    v.selectAction();v.selectAction();Test.assert(v.beast.dev);Test.assert(v.menu.equals("Dev Tools"));
    v.selection=0;v.selectAction();v.selection=3;v.selectAction();Test.assertEqual(v.beast.speed,100);
    v.selection=1;v.selectAction();v.selection=2;v.selectAction();Test.assertEqual(v.beast.ageDays(),7);
    v.openMenu("Settings");v.selectAction();v.selectAction();Test.assert(!v.beast.dev);Test.assertEqual(v.beast.ageDays(),0);
    Test.assertEqual(v.beast.xp(),0l);return true;
}
(:test)
function miniGamesTest(logger){
    var s=TestSupport.fixture();var star=new BeastGameView(s,0);star.selectAction();
    for(var i=0;i<5;i++){star.elapsed=i*16+4;star.selectAction();}
    Test.assertEqual(star.phase,3);Test.assertEqual(star.hits,5);Test.assertEqual(s.number("games"),1);
    var memory=new BeastGameView(s,1);memory.selectAction();memory.phase=2;
    for(var i=0;i<memory.sequence.size();i++){memory.memoryInput(memory.sequence[i]);}
    Test.assertEqual(memory.phase,3);Test.assertEqual(s.number("games"),2);Test.assertEqual(s.xp(),0l);
    var scan=new BeastGameView(s,1);scan.scanning=true;scan.sequence=[0,1,2];scan.phase=2;
    for(var i=0;i<3;i++){scan.tick=i*4;scan.selectAction();}Test.assertEqual(scan.phase,3);
    // The scan-mode game used the third rewarded slot. Further play is practice.
    var quit=new BeastGameView(s,0);quit.selectAction();Test.assertEqual(s.number("games"),3);
    // Automatic timeout completes exactly five attempts and no duplicate award.
    var timeout=new BeastGameView(s,0);timeout.selectAction();
    for(var i=0;i<80;i++){timeout.refresh();}
    Test.assertEqual(timeout.phase,3);Test.assertEqual(s.number("games"),3);
    timeout.refresh();Test.assertEqual(s.number("games"),3);return true;
}
(:test)
function activeBalanceAndArchiveTest(logger){
    var s=TestSupport.fixture();
    for(var i=0;i<21;i++){s.testNow+=86400;s.tick();s.observe(s.today(),10000);}
    s.tick();Test.assertEqual(s.stage(),5);Test.assertEqual(s.xp(),210000l);
    var steps=s.xp();Test.assert(s.newEgg());Test.assertEqual(s.stage(),0);Test.assertEqual(s.xp(),steps);Test.assertEqual(s.growth(),0l);
    Test.assert(s.store.read("v4.archive")!=null);Test.assert(s.number("collection")>0);
    s.testNow+=86400;s.tick();Test.assertEqual(s.stage(),1);return true;
}
(:test)
function devInventoryAndItemsTest(logger){
    var s=TestSupport.fixture();var d=s.enableDev();d.data["items"][5]=1;Test.assert(d.useItem(5));Test.assertEqual(d.number("equipped"),5);
    d.newEgg();d.commit();Test.assertEqual(s.store.read("v4")["items"][5],0);Test.assert(s.store.read("v4.dev.archive")==null);return true;
}
(:test)
function earlySaveAgeTest(logger){
    var s=new TekuTekuBeastState();s.testNow=1792108800l;s.skipWatch=true;
    var birthday=s.dateKey(new Toybox.Time.Moment((s.testNow-30*86400).toNumber()));
    s.store.memory={"birth"=>birthday,"xp"=>300000,"family"=>2,"friendship"=>75,"snacks"=>4};s.start();
    Test.assertEqual(s.ageDays(),30);Test.assertEqual(s.stage(),5);Test.assertEqual(s.family(),2);
    Test.assertEqual(s.friendship(),75);Test.assertEqual(s.xp(),300000l);return true;
}
(:test)
function freshEggScenarioTest(logger){
    var s=TestSupport.fixture();s.testNow+=86400;s.tick();s.observe(s.today(),3000);s.commit();
    var v=new TekuTekuBeastView();v.live=s;v.beast=s.enableDev();v.openMenu("Reset scenario");v.selection=1;v.selectAction();
    Test.assert(v.beast.dev);Test.assertEqual(v.beast.stage(),0);Test.assertEqual(v.beast.growth(),0l);Test.assertEqual(v.beast.xp(),3000l);
    v.beast.careReward(300,0);v.beast.jump(7*3600);Test.assertEqual(v.beast.stage(),0);
    v.beast.jump(3600);Test.assertEqual(v.beast.stage(),1);Test.assertEqual(s.store.read("v4")["stageFloor"],1);return true;
}
(:test)
function nonStepActivityAndCollectionTest(logger){
    var s=TestSupport.fixture();var day=s.today();s.activityRewards(day,0,0,0);s.activityRewards(day,0,50,2500);
    Test.assertEqual(s.xp(),0l);Test.assertEqual(s.number("activityBonus"),5000l);Test.assertEqual(s.number("adventure"),5);
    s.activityRewards(day,0,50,2500);Test.assertEqual(s.number("activityBonus"),5000l);
    for(var i=0;i<8;i++){s.data["adventure"]++;s.explore(0);}Test.assertEqual(s.number("discoveryMask"),255);
    s.data["fullness"]=50;s.useItem(0);Test.assertEqual(s.number("discoveryMask"),255);Test.assertEqual(s.xp(),0l);return true;
}
(:test)
function foregroundEvolutionTest(logger){
    var s=TestSupport.fixture();s.testNow+=86400;s.syncToday();Test.assertEqual(s.number("evolutionPending"),1);
    var view=new TekuTekuBeastView();view.beast=s;view.consumeEvolution();
    Test.assertEqual(s.number("evolutionPending"),0);Test.assert(view.animation.equals("evolve"));
    s.tick();Test.assertEqual(s.number("evolutionPending"),0);Test.assertEqual(s.xp(),0l);return true;
}
(:test)
function foregroundTimerLifecycleTest(logger){
    var app=Toybox.Application.getApp();var prior=app.activeView;
    var view=new TekuTekuBeastView();view.beast=TestSupport.fixture();view.onShow();
    var started=view.refresher!=null;app.onInactive(null);var inactiveStopped=view.refresher==null;
    app.onActive(null);var resumed=view.refresher!=null;view.onHide();
    var game=new BeastGameView(view.beast,0);game.onShow();game.onHide();
    var reconciler=new TekuTekuBeastState();reconciler.store=view.beast.store;
    reconciler.skipWatch=true;reconciler.testNow=view.beast.testNow;reconciler.start();
    reconciler.observe(reconciler.today(),5000);reconciler.commit();
    game.onShow();var caughtUp=game.beast.xp()==5000l;game.onHide();
    var gameStopped=game.refresher==null;app.activeView=prior;
    Test.assert(started && inactiveStopped && resumed && view.refresher==null && gameStopped);
    Test.assert(caughtUp);
    return true;
}
