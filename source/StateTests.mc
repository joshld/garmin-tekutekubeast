using Toybox.Test;
using Toybox.Lang;

(:test)
function compactGlanceAndDeferredCatchupTest(logger){
    var s=TestSupport.fixture();s.observe(s.today(),3000);s.data["friendship"]=71;
    s.data["items"][7]=9;s.beginSession(1);s.commit();
    var cache=s.store.read("glance.v1");Test.assert(cache!=null);
    Test.assert(!cache.hasKey("days"));Test.assert(!cache.hasKey("sessions"));
    Test.assertEqual(cache["friendship"],71);
    var xp=s.xp();var serial=s.number("gameSerial");s.testNow+=26*86400;
    s.syncHistory();Test.assertEqual(s.xp(),xp);Test.assertEqual(s.stage(),5);
    Test.assertEqual(s.number("evolutionPending"),1);Test.assertEqual(s.data["items"][7],9);
    Test.assertEqual(s.number("gameSerial"),serial);s.data["evolutionPending"]=0;s.commit();
    var reload=new TekuTekuBeastState();reload.store=s.store;reload.skipWatch=true;reload.testNow=s.testNow;
    reload.syncHistory();Test.assertEqual(reload.number("evolutionPending"),0);
    Test.assertEqual(reload.friendship(),71);Test.assertEqual(reload.xp(),xp);
    var before=reload.store.writes;reload.commit();Test.assertEqual(reload.store.writes,before);
    return true;
}

(:test)
function solarSeasonsTest(logger){
    var june=BeastSky.midnight(2026,6,21);var december=BeastSky.midnight(2026,12,21);
    // Broad 10-minute envelopes for NOAA approximation vs published civil
    // sunrise tables; never assert second-level astronomical precision.
    var london=BeastSky.calculate(june,51.5074,-0.1278);
    Test.assert(BeastSky.abs(london[0]-(june+3*3600+43*60))<600);
    Test.assert(BeastSky.abs(london[1]-(june+20*3600+21*60))<600);
    var winter=BeastSky.calculate(december,51.5074,-0.1278);
    Test.assert(BeastSky.abs(winter[0]-(december+8*3600+4*60))<600);
    Test.assert(BeastSky.abs(winter[1]-(december+15*3600+54*60))<600);
    var brisbane=BeastSky.calculate(december,-27.47,153.03);
    Test.assert(BeastSky.abs(brisbane[0]-(december-5*3600-11*60))<600);
    Test.assert(BeastSky.abs(brisbane[1]-(december+8*3600+42*60))<600);
    var north=BeastSky.calculate(june,78.2,15.6);Test.assertEqual(north[2],1);
    Test.assertEqual(BeastSky.calculate(december,78.2,15.6)[2],-1);
    Test.assertEqual(BeastSky.calculate(june,-89.99,0.0)[2],-1);
    Test.assertEqual(BeastSky.calculate(december,-89.99,0.0)[2],1);
    Test.assert(BeastSky.valid(0,0));Test.assert(!BeastSky.valid(91,0));Test.assert(!BeastSky.valid(0,181));
    var leap=BeastSky.calculate(BeastSky.midnight(2028,2,29),0.0,179.9);Test.assert(leap[1]>leap[0]);return true;
}
(:test)
function v051TimeZoneSolarBracketTest(logger){
    var date=BeastSky.midnight(2026,1,1);var days=[];
    for(var i=-1;i<=1;i++){days.add(BeastSky.calculate(date+i*86400,0.0,179.9));}
    var now=date+20*3600;var index=BeastSky.chooseDay(now,days);Test.assertEqual(index,2);
    Test.assert(BeastSky.sample(now,days[index],days[index-1],[0l,0l,1])[2]);
    days=[];for(var i=-1;i<=1;i++){days.add(BeastSky.calculate(date+i*86400,0.0,0.0));}
    now=days[1][1]+300;index=BeastSky.chooseDay(now,days);Test.assertEqual(index,2);
    Test.assertEqual(BeastSky.sample(now,days[index],days[index-1],[0l,0l,1])[0],2);
    now=days[2][0]-300;Test.assertEqual(BeastSky.sample(now,days[2],days[1],[0l,0l,1])[0],0);
    days=[];for(var i=-1;i<=1;i++){days.add(BeastSky.calculate(date+i*86400,0.0,-179.9));}
    now=date-86400+12*3600;index=BeastSky.chooseDay(now,days);Test.assertEqual(index,0);
    Test.assert(!BeastSky.sample(now,days[0],[0l,0l,-1],days[1])[2]);return true;
}
(:test)
function skyCycleAndSleepTest(logger){
    var s=TestSupport.fixture();var before=s.store.copy(s.data);var now=s.realNow();
    var w=new BeastWorld(s);w.update(now,false);Test.assertEqual(w.source,"FIXED 06-18");
    var count=w.computations;w.update(now+1,false);Test.assertEqual(w.computations,count);
    Test.assert(w.accept(-27.47,153.03,now));Test.assert(!w.accept(95,0,now));
    w.update(now,false);Test.assertEqual(w.source,"SAVED LOCATION");
    var today=w.days[1];var dawn=BeastSky.sample(today[0],today,w.days[0],w.days[2]);Test.assertEqual(dawn[0],0);Test.assert(dawn[2]);
    var noon=BeastSky.sample((today[0]+today[1])/2,today,w.days[0],w.days[2]);Test.assertEqual(noon[0],1);Test.assert(BeastSky.abs(noon[1]-0.5)<0.001);
    Test.assertEqual(BeastSky.sample(today[1],today,w.days[0],w.days[2])[0],2);
    var night=BeastSky.sample(today[1]+3600,today,w.days[0],w.days[2]);Test.assertEqual(night[0],3);Test.assert(!night[2]);
    // Changing astronomical phase cannot modify any sleep flag or pet ledger.
    Test.assertEqual(s.number("sleepMode"),before["sleepMode"]);Test.assertEqual(s.number("sleepUntil"),before["sleepUntil"]);
    Test.assertEqual(s.xp(),before["xp"]);Test.assertEqual(s.number("baseGrowth"),before["baseGrowth"]);
    var reopened=new BeastWorld(s);reopened.update(now,false);Test.assertEqual(reopened.days[1][0],today[0]);
    var chosen=w.choose(1,0);Test.assertEqual(w.choose(4,5),chosen);w.setTheme(4);Test.assertEqual(w.choose(1,0),3);
    var d=s.enableDev();var dw=new BeastWorld(d);dw.setTheme(2);dw.accept(40,-74,now);dw.preview=3;dw.update(now,false);
    Test.assertEqual(dw.sample[0],3);var real=new BeastWorld(s);Test.assertEqual(real.prefs["environment"],4);Test.assertEqual(real.prefs["lat"],-27.47);
    Test.assertEqual(s.store.read("v4")["xp"],before["xp"]);return true;
}

(:test)
module TestSupport {
    function same(a,b){
        if(a instanceof Lang.Dictionary){if(!(b instanceof Lang.Dictionary) || a.size()!=b.size()){return false;}var keys=a.keys();for(var i=0;i<keys.size();i++){if(!b.hasKey(keys[i]) || !same(a[keys[i]],b[keys[i]])){return false;}}return true;}
        if(a instanceof Lang.Array){if(!(b instanceof Lang.Array) || a.size()!=b.size()){return false;}for(var i=0;i<a.size();i++){if(!same(a[i],b[i])){return false;}}return true;}
        return a==b;
    }
    function fixture(){
        var s=new TekuTekuBeastState();s.store.memory={};s.skipWatch=true;s.testNow=1792108800l;s.start();return s;
    }
}
(:test)
function v05WorldSaveAndDateTest(logger){
    var s=TestSupport.fixture();s.observe(s.today(),123456);s.data["items"]=[2,3,4,5,6,7,8,9];s.data["collection"]=15;s.data["rareCollection"]=3;
    s.data["friendship"]=71;s.data["snacks"]=12;s.commit();var before=s.store.copy(s.store.read("v4"));
    var w=new BeastWorld(s);w.setTheme(3);w.accept(51.5,-0.1,s.realNow());w.update(s.realNow(),false);
    w.update(s.realNow()+86400,false);Test.assertEqual(w.computations,2);
    Test.assert(TestSupport.same(before,s.store.read("v4")));
    var reload=new TekuTekuBeastState();reload.store=s.store;reload.skipWatch=true;reload.testNow=s.testNow;reload.start();
    Test.assert(TestSupport.same(before,reload.data));
    var confirmed=w.prefs["manualLat"];w.draftLat=-40.0;w.draftLon=-74.0;w.setTheme(2);
    Test.assertEqual(s.store.read("world.v1")["manualLat"],confirmed);
    var unconfirmed=new BeastWorld(s);Test.assertEqual(unconfirmed.draftLat,confirmed);
    Test.assert(w.confirmManual());Test.assertEqual(s.store.read("world.v1")["manualLat"],-40.0);
    Test.assert(TestSupport.same(before,s.store.read("v4")));
    var d=s.enableDev();var devBefore=s.store.copy(s.store.read("v4"));var dw=new BeastWorld(d);var prefs=s.store.copy(s.store.read("world.v1"));
    dw.prefs["locationMode"]=2;dw.prefs["manualSet"]=1;dw.prefs["manualLat"]=-40.0;dw.update(s.realNow(),false);dw.save();
    Test.assert(TestSupport.same(prefs,s.store.read("world.v1")));
    // Enabling DEV reconciles real elapsed care/growth first, as in v0.5.
    // Only changes made AFTER that boundary must leave this snapshot identical.
    Test.assert(TestSupport.same(devBefore,s.store.read("v4")));
    s.data["sleepMode"]=2;s.data["sleepUntil"]=0l;var asleep=s.isSleeping();
    w.update(s.realNow()+43200,false);Test.assertEqual(s.isSleeping(),asleep);
    return true;
}
(:test)
function v051MemoryAndStarTimingTest(logger){
    var s=TestSupport.fixture();var m=new BeastGameView(s,1);m.begin();m.sequence=[0,0,2];
    m.elapsed=m.tempo()-1;Test.assertEqual(m.displayedMove(),0);m.elapsed=m.tempo();Test.assertEqual(m.displayedMove(),-1);
    m.elapsed=m.tempo()+m.cueGap();Test.assertEqual(m.displayedMove(),0);
    m.elapsed=2*(m.tempo()+m.cueGap())-1;Test.assertEqual(m.displayedMove(),-1);
    m.checkpoint();var old=s.store.copy(m.session);old.remove("timingV051");old["elapsed"]=6;
    var resumed=new BeastGameView(s,1);resumed.restore(old);Test.assertEqual(resumed.elapsed,7);Test.assertEqual(resumed.sequence[0],0);
    var star=new BeastGameView(s,0);Test.assertEqual(star.period(),16);star.round=1;Test.assertEqual(star.period(),12);
    star.round=2;Test.assertEqual(star.period(),9);Test.assertEqual(star.jumpDuration(),5);
    star.begin();star.elapsed=10;star.hits=2;star.checkpoint();var prior=s.store.copy(star.session);prior.remove("timingV051");
    var again=new BeastGameView(s,0);again.restore(prior);Test.assertEqual(again.elapsed,8);Test.assertEqual(again.hits,2);Test.assertEqual(again.session["id"],prior["id"]);
    s.data["easy"]=1;star.round=0;Test.assertEqual(star.period(),24);star.round=1;Test.assertEqual(star.period(),20);star.round=2;Test.assertEqual(star.period(),16);
    Test.assertEqual(m.tempo(),8);Test.assertEqual(m.cueGap(),1);Test.assertEqual(s.xp(),0l);return true;
}
(:test)
function v051DirtySaveAndDuplicateStepTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=2;s.observe(s.today(),3000);s.activityRewards(s.today(),3000,null,null);s.commit();
    s.store.writes=0;s.store.skipped=0;
    for(var i=0;i<100;i++){s.commit();Test.assert(s.stepNoop(3000,null,null));}
    Test.assertEqual(s.store.writes,0);Test.assert(s.store.skipped>=100);Test.assertEqual(s.xp(),3000l);
    Test.assert(!s.stepNoop(3001,null,null));s.data["minutesBase"]=0;Test.assert(!s.stepNoop(3000,20,null));
    s.data["pushBase"]=0;Test.assert(!s.stepNoop(3000,null,1000));
    // One canonical write plus its tiny read-only Glance cache, then no-op.
    s.data["friendship"]++;s.commit();Test.assertEqual(s.store.writes,2);s.commit();Test.assertEqual(s.store.writes,2);
    s.data["poopDue"]=s.now();Test.assert(!s.stepNoop(3000,null,null));s.data["poopDue"]=0l;
    s.testNow+=61;Test.assert(!s.stepNoop(3000,null,null));s.syncToday();
    var after=s.xp();s.observe(s.today(),3001);s.commit();Test.assertEqual(s.xp(),after+1);
    logger.debug("BATTERY_AUDIT: 100 identical commits -> 0 writes; duplicate-step preflight=100/100; new step persisted");return true;
}
(:test)
function v051RoamingBoundsTest(logger){
    var v=new TekuTekuBeastView();v.beast=TestSupport.fixture();var profiles=[[240,96],[260,96],[280,96],[390,144],[416,144],[454,192]];
    for(var p=0;p<profiles.size();p++){
        var width=profiles[p][0];var size=profiles[p][1];var minX=10000;var maxX=0;var minY=10000;var maxY=0;var radius=width/2-8;
        for(var i=0;i<v.roamX.size();i++){
            v.positionCreature(width,width,size,width*(0.5+v.roamX[i]),width*v.roamY[i]);var box=v.petBounds;
            minX=v.beast.min(minX,box[0]);maxX=v.beast.max(maxX,box[0]);minY=v.beast.min(minY,box[1]);maxY=v.beast.max(maxY,box[1]);
            for(var corner=0;corner<4;corner++){var x=box[0]+(corner%2==0?0:box[2])-width/2;var y=box[1]+(corner<2?0:box[3])-width/2;Test.assert(x*x+y*y<=radius*radius);}
            Test.assert(box[1]>=width*0.18-1);Test.assert(box[1]+box[3]<=width*0.745);
        }
        Test.assert(maxX-minX>=width*0.30);Test.assert(maxY-minY>=width*0.14);
        logger.debug("ROAM_AUDIT: "+width+"px canvas="+size+" horizontal="+(maxX-minX)+" vertical="+(maxY-minY));
    }return true;
}
(:test)
function v051RedrawAndTimerAuditTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=2;s.data["motion"]=0;var v=new TekuTekuBeastView();v.beast=s;
    Test.assertEqual(v.desiredPeriod(),5000);v.timerPeriod=5000;
    for(var i=0;i<40;i++){v.refresh();}Test.assertEqual(v.redrawRequests,1);Test.assert(v.refresher==null);
    s.data["motion"]=2;s.data["energy"]=0;Test.assertEqual(v.desiredPeriod(),5000);s.data["energy"]=80;
    var m=new BeastGameView(s,1);m.begin();m.sequence=[0,0,2];m.timerPeriod=250;
    for(var i=0;i<21;i++){m.refresh();}Test.assertEqual(m.phase,2);Test.assert(m.gameRedraws<=8);
    logger.debug("REDRAW_AUDIT: 40 unchanged Pet callbacks -> "+v.redrawRequests+" redraw; 21 memory cue ticks -> "+m.gameRedraws+" redraws");return true;
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
    Test.assertEqual(v.rows.size(),8);v.selection=6;v.selectAction();Test.assert(v.menu.equals("Settings"));
    v.selectAction();v.selectAction();Test.assert(v.beast.dev);Test.assert(v.menu.equals("Dev Tools"));
    v.selection=0;v.selectAction();v.selection=3;v.selectAction();Test.assertEqual(v.beast.speed,100);
    v.selection=1;v.selectAction();v.selection=2;v.selectAction();Test.assertEqual(v.beast.ageDays(),7);
    v.openMenu("Settings");v.selectAction();v.selectAction();Test.assert(!v.beast.dev);Test.assertEqual(v.beast.ageDays(),0);
    Test.assertEqual(v.beast.xp(),0l);return true;
}
(:test)
function miniGamesTest(logger){
    var s=TestSupport.fixture();s.data["haptics"]=0;
    var star=new BeastGameView(s,0);Test.assertEqual(star.desiredGamePeriod(),1000);star.selectAction();Test.assertEqual(star.desiredGamePeriod(),250);
    Test.assertEqual(star.resultTouchChoice(220),0);Test.assertEqual(star.resultTouchChoice(255),1);
    for(var attempt=0;attempt<15;attempt++){
        star.lane=star.target;star.elapsed=(star.period()/2).toNumber()-1;star.selectAction();star.refresh();
        Test.assert(star.caught);
        while(star.phase==1 && star.attempts==attempt){star.refresh();}
    }
    Test.assertEqual(star.phase,3);Test.assertEqual(star.hits,15);Test.assertEqual(s.number("games"),1);
    Test.assertEqual(star.desiredGamePeriod(),1000);
    var scout=new BeastGameView(s,2);scout.result="SCOUT COMPLETE";Test.assert(scout.resultDetail().equals("SCOUT: NO LOOT"));
    scout.result="FOUND BERRY";Test.assert(scout.resultDetail().equals("IN YOUR COLLECTION"));
    Test.assert(scout.trailChoice().equals("> HELP"));scout.node=1;Test.assert(scout.trailChoice().equals("> CROSS"));
    scout.choice=1;Test.assert(scout.trailChoice().equals("> DETOUR"));scout.node=2;Test.assert(scout.trailChoice().equals("> PUSH OPEN"));
    var memory=new BeastGameView(s,1);memory.selectAction();
    for(var round=0;round<3;round++){
        memory.phase=2;
        while(memory.phase==2){memory.memoryInput(memory.sequence[memory.cursor]);}
        memory.continueMemory();
    }
    Test.assertEqual(memory.phase,3);Test.assertEqual(memory.hits,3);Test.assertEqual(s.number("games"),2);
    var scan=new BeastGameView(s,1);scan.scanning=true;scan.selectAction();
    for(var round=0;round<3;round++){
        scan.phase=2;
        while(scan.phase==2){scan.tick=scan.sequence[scan.cursor]*6;scan.selectAction();}
        scan.continueMemory();
    }
    Test.assertEqual(scan.phase,3);Test.assertEqual(s.number("games"),3);
    var timeout=new BeastGameView(s,0);timeout.selectAction();
    for(var i=0;i<300;i++){timeout.refresh();}
    Test.assertEqual(timeout.phase,3);Test.assertEqual(s.number("games"),3);Test.assertEqual(s.xp(),0l);
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
    var view=new TekuTekuBeastView();view.beast=s;view.page=2;view.consumeEvolution();
    Test.assertEqual(s.number("evolutionPending"),0);Test.assert(view.animation.equals("evolve"));Test.assertEqual(view.page,0);
    s.tick();Test.assertEqual(s.number("evolutionPending"),0);Test.assertEqual(s.xp(),0l);return true;
}
(:test)
function foregroundTimerLifecycleTest(logger){
    var app=Toybox.Application.getApp();var prior=app.activeView;
    var view=new TekuTekuBeastView();view.beast=TestSupport.fixture();view.onShow();
    var started=view.refresher!=null;
    view.beast.data["stageFloor"]=1;view.beast.data["motion"]=2;view.beast.data["energy"]=80;view.beast.data["sleepMode"]=2;
    view.tick=0;view.switchPage(1);Test.assertEqual(view.timerPeriod,5000);
    view.back();Test.assertEqual(view.timerPeriod,250);
    view.openMenu("Actions");view.tunePetTimer();Test.assertEqual(view.timerPeriod,5000);
    view.back();Test.assertEqual(view.timerPeriod,250);
    app.onInactive(null);var inactiveStopped=view.refresher==null;
    view.switchPage(1);view.back();Test.assert(view.refresher==null);
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

(:test)
function v04UpgradePreservationTest(logger){
    var old=TestSupport.fixture();old.observe(old.today(),5974);old.data["family"]=2;old.data["stageFloor"]=3;
    old.data["friendship"]=77;old.data["collection"]=7;old.data["rareCollection"]=2;old.data["items"][6]=8;
    old.data["snacks"]=5;old.data["careGrowth"]=250l;old.data["activityBonus"]=3000l;old.commit();
    var saved=old.store.read("v4");
    var newKeys=["sleepMode","bedMinute","wakeMinute","watchBed","watchWake","nextBed","nextWake","scheduleAt","sleepSource","autoLights","lights","lightsUntil","vibeStyle","gameSerial","gameDone","session","sessions","gameClaims","easy","v5"];
    for(var i=0;i<newKeys.size();i++){saved.remove(newKeys[i]);}
    old.store.write("v4",saved);var restored=new TekuTekuBeastState();restored.store=old.store;restored.skipWatch=true;restored.testNow=old.testNow;restored.start();
    Test.assertEqual(restored.xp(),5974l);Test.assertEqual(restored.stage(),3);Test.assertEqual(restored.family(),2);
    Test.assertEqual(restored.friendship(),77);Test.assertEqual(restored.snacks(),5);Test.assertEqual(restored.number("collection"),7);
    Test.assertEqual(restored.number("rareCollection"),2);Test.assertEqual(restored.data["items"][6],8);
    Test.assertEqual(restored.number("careGrowth"),250l);Test.assertEqual(restored.number("activityBonus"),3000l);
    Test.assertEqual(restored.data["counts"][old.today()%32],5974);Test.assertEqual(restored.number("version"),4);
    Test.assertEqual(restored.data["sessions"].size(),3);restored.commit();restored.data=null;restored.start();
    Test.assertEqual(restored.number("gameSerial"),0);Test.assertEqual(restored.xp(),5974l);return true;
}
(:test)
function scheduledSleepAndLightsTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=1;s.data["bedMinute"]=1320;s.data["wakeMinute"]=420;
    s.testNow+=((1320-BeastSleep.minuteAt(s.now())+1440)%1440)*60;
    s.data["lastCare"]=s.now();s.data["energy"]=0;s.data["poop"]=2;Test.assert(s.isNight());Test.assert(s.isDark());Test.assert(s.mood().equals("ASLEEP"));
    var v=new TekuTekuBeastView();v.beast=s;v.animation="happy";v.animationTicks=12;Test.assert(v.visualState().equals("sleep"));
    s.toggleLights();Test.assert(!s.isDark());Test.assert(s.isNight());s.testNow+=8*3600;s.tick();Test.assert(s.number("energy")>=64);
    Test.assert(s.isNight());Test.assert(s.isDark());s.testNow+=3600;s.tick();Test.assert(!s.isNight());
    s.data["poop"]=0;s.data["energy"]=0;Test.assert(s.mood().equals("SLEEPY"));Test.assert(v.visualState().equals("sleep"));
    s.rest();Test.assert(s.mood().equals("RESTING"));var energy=s.number("energy");s.testNow-=3600;s.tick();Test.assertEqual(s.number("energy"),energy);
    s.data["sleepMode"]=2;s.data["sleepUntil"]=0l;s.data["energy"]=80;Test.assert(!s.isNight());return true;
}
(:test)
function sleepUpcomingFallbackTest(logger){
    Test.assert(!BeastSleep.validSchedule(0,0));Test.assert(!BeastSleep.validSchedule(1441,420));Test.assert(BeastSleep.validSchedule(1320,420));
    var s=TestSupport.fixture();s.data["nextBed"]=s.now()+18*3600;s.data["nextWake"]=s.now()+2*3600;
    Test.assert(s.isNight());s.data["nextBed"]=s.now()+2*3600;s.data["nextWake"]=s.now()+10*3600;Test.assert(!s.isNight());
    s.data["nextBed"]=0l;s.data["nextWake"]=0l;s.data["watchBed"]=0;s.data["watchWake"]=1439;
    Test.assert(s.isNight());s.data["watchWake"]=0;Test.assert(!s.isNight());
    Test.assert(BeastSleep.inWindow(60,1320,420));Test.assert(!BeastSleep.inWindow(600,1320,420));
    Test.assert(BeastSleep.inWindow(600,540,1020));
    s.data["sleepMode"]=1;s.data["bedMinute"]=1320;s.data["wakeMinute"]=420;
    s.testNow+=((1320-BeastSleep.minuteAt(s.now())+1440)%1440)*60;
    s.data["lastCare"]=s.now();s.data["energy"]=0;s.data["poop"]=0;s.data["fullness"]=80;s.data["friendship"]=25;
    s.testNow+=9*3600;var forecast=BeastSleep.previewMood(s.data,s.now());Test.assertEqual(s.number("energy"),0);
    Test.assert(BeastSleep.forecastEnergy(s.data,s.now())>=64);s.tick();Test.assert(s.mood().equals(forecast));return true;
}
(:test)
function gameSessionAtomicityTest(logger){
    var s=TestSupport.fixture();s.data["adventure"]=2;s.commit();var trip=s.beginSession(2);var id=trip["id"];
    Test.assertEqual(s.number("adventure"),1);Test.assertEqual(s.beginSession(2)["id"],id);Test.assertEqual(s.number("adventure"),1);
    trip["route"]=3;trip["node"]=2;trip["finds"]=3;Test.assert(s.saveSession(trip));
    s.data=null;s.start();Test.assertEqual(s.data["sessions"][2]["route"],3);Test.assertEqual(s.number("adventure"),1);
    var answer=s.completeSession(trip,true);Test.assert(answer.find("FOUND ")==0);Test.assertEqual(s.number("encounters"),1);
    Test.assertEqual(s.friendship(),1);
    Test.assert(s.completeSession(trip,true).equals("ALREADY SAVED"));Test.assert(!s.saveSession(trip));Test.assertEqual(s.number("encounters"),1);
    Test.assertEqual(s.friendship(),1);
    Test.assertEqual(s.xp(),0l);var arcade=s.beginSession(0);var slots=s.number("games");s.completeSession(arcade,true);s.completeSession(arcade,true);
    Test.assertEqual(s.number("games"),slots+1);Test.assertEqual(s.xp(),0l);return true;
}
(:test)
function gameRetryReplayAndSuspendTest(logger){
    var s=TestSupport.fixture();s.data["haptics"]=0;var game=new BeastGameView(s,1);game.selectAction();game.phase=2;
    var first=game.sequence[0];game.memoryInput((first+1)%3);Test.assertEqual(game.phase,4);Test.assert(game.replayRound);Test.assertEqual(s.number("games"),0);
    game.continueMemory();Test.assertEqual(game.phase,1);game.phase=2;game.cursor=0;game.memoryInput((first+1)%3);Test.assert(!game.replayRound);
    game.continueMemory();Test.assertEqual(game.round,1);game.onHide();var resumed=new BeastGameView(s,1);resumed.onShow();resumed.onHide();
    Test.assertEqual(resumed.round,1);Test.assertEqual(resumed.retries,0);Test.assertEqual(s.number("games"),0);
    var trip=new BeastGameView(s,2);s.data["adventure"]=1;trip.trail=2;trip.selectAction();
    for(var stop=0;stop<3;stop++){for(var t=0;t<12;t++){trip.refresh();}Test.assertEqual(trip.phase,2);trip.choice=stop%2;trip.selectAction();Test.assertEqual(trip.phase,4);trip.nextTrail();}
    Test.assertEqual(trip.phase,3);Test.assertEqual(s.number("adventure"),0);Test.assertEqual(s.number("encounters"),1);
    Test.assertEqual(s.number("games"),0);Test.assertEqual(s.xp(),0l);
    // Simulate interruption after the atomic session/debit, before the view's
    // first sequence/target/travel checkpoint. Reopening must finish setup.
    var cold=TestSupport.fixture();var initialMemory=cold.beginSession(1);
    var recoveredMemory=new BeastGameView(cold,1);recoveredMemory.onShow();recoveredMemory.onHide();
    Test.assertEqual(recoveredMemory.sequence.size(),3);Test.assertEqual(recoveredMemory.session["id"],initialMemory["id"]);
    cold.data["adventure"]=2;var initialTrip=cold.beginSession(2);Test.assertEqual(initialTrip["phase"],5);
    initialTrip["phase"]=1;cold.saveSession(initialTrip); // repair an older incomplete start too
    var recoveredTrip=new BeastGameView(cold,2);recoveredTrip.onShow();recoveredTrip.onHide();
    Test.assertEqual(recoveredTrip.phase,5);Test.assertEqual(cold.number("adventure"),1);
    Test.assertEqual(recoveredTrip.session["id"],initialTrip["id"]);
    var initialBounce=cold.beginSession(0);var recoveredBounce=new BeastGameView(cold,0);
    recoveredBounce.onShow();recoveredBounce.onHide();Test.assert(cold.data["sessions"][0].hasKey("target"));
    Test.assertEqual(cold.data["sessions"][0]["seed"],(initialBounce["seed"]*17+11)%65521);
    Test.assertEqual(cold.number("games"),0);Test.assertEqual(cold.xp(),0l);return true;
}
(:test)
function devNewSystemsIsolationTest(logger){
    var s=TestSupport.fixture();s.observe(s.today(),4200);s.commit();var d=s.enableDev();d.simulateSleep(true);
    d.toggleLights();d.data["adventure"]=20;var trip=d.beginSession(2);trip["finds"]=3;d.completeSession(trip,true);
    d.data["easy"]=1;d.jump(7*86400);d.commit();
    var restored=new TekuTekuBeastState();restored.store=s.store;restored.testNow=s.testNow;restored.skipWatch=true;restored.start();
    Test.assertEqual(restored.number("adventure"),0);Test.assertEqual(restored.number("encounters"),0);Test.assertEqual(restored.number("easy"),0);
    Test.assertEqual(restored.number("sleepMode"),0);Test.assertEqual(restored.number("lightsUntil"),0l);Test.assertEqual(restored.xp(),4200l);
    Test.assertEqual(restored.number("gameSerial"),0);return true;
}
(:test)
function sessionMidnightAndPracticeTest(logger){
    var s=TestSupport.fixture();s.data["games"]=3;var session=s.beginSession(0);var energy=s.number("energy");
    Test.assert(s.completeSession(session,true).equals("PRACTICE"));Test.assertEqual(s.number("energy"),energy);
    var next=s.beginSession(1);s.testNow+=86400;s.tick();Test.assertEqual(s.number("games"),0);
    s.completeSession(next,true);Test.assertEqual(s.number("games"),1);s.data=null;s.start();s.completeSession(next,true);
    Test.assertEqual(s.number("games"),1);var trip=s.beginSession(2);Test.assert(trip["practice"]);
    trip["finds"]=9;Test.assert(s.completeSession(trip,true).equals("SCOUT COMPLETE"));
    Test.assertEqual(s.number("encounters"),0);Test.assertEqual(s.number("adventure"),0);Test.assertEqual(s.number("discoveryMask"),0);
    Test.assertEqual(s.xp(),0l);return true;
}
(:test)
function quietBedtimeFeedbackTest(logger){
    var s=TestSupport.fixture();var d=s.enableDev();d.simulateSleep(true);d.data["sound"]=1;d.data["haptics"]=1;
    new FeedbackManager().testCue(d,true);Test.assert(FeedbackManager.lastStatus.equals("BEDTIME: QUIET"));
    Test.assertEqual(d.number("sound"),1);Test.assertEqual(d.number("haptics"),1);
    d.simulateSleep(false);d.data["sound"]=0;d.data["haptics"]=0;FeedbackManager.lastCue=-2000;
    new FeedbackManager().cue(d,"eat");Test.assert(FeedbackManager.lastStatus.equals("FEEDBACK OFF"));
    Test.assertEqual(s.xp(),0l);return true;
}
