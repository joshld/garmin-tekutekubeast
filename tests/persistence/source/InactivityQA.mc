using Toybox.Test;using Toybox.Application;using Toybox.Application.Storage;
// Keep QA symbols below legacy SDK module-member limits.
module InactivityQA {
// Deterministic monotonic clock; actual production scheduler/event boundaries.
class IdleTicket {function initialize(){}function stop(){}}
class IdleClock extends BeastInactivity {
 var ms=0;var arms=0;var delay=0;
 function clock(){return ms;}
 function arm(value){arms++;delay=value;timer=new IdleTicket();}
}
class IdlePet extends TekuTekuBeastView {
 var exited=false;var exits=0;
 function initialize(s){TekuTekuBeastView.initialize();beast=s;}
 function exitApplication(){exits++;exited=true;}
}
class IdleGame extends BeastGameView {
 var exited=false;
 function initialize(s,k){BeastGameView.initialize(s,k);}
 function exitApplication(){exited=true;}
}
class IdleBattle extends BeastBattleView {
 var exited=false;
 function initialize(s){BeastBattleView.initialize(s);}
 function exitApplication(){exited=true;}
}
module IdleSupport {
 function bind(view){var idle=new IdleClock();var app=Application.getApp();app.inactivity=idle;app.activeView=view;idle.update(view);return idle;}
 function done(view){var app=Application.getApp();if(app.inactivity!=null){app.inactivity.stop();}view.onHide();app.activeView=null;app.inactivity=null;}
}
(:test)
function inactivityDefaultsTest(logger){
 var s=PersistenceSupport.fixture(false);Test.assertEqual(s.number("autoExit"),300);var expected=s.xp();
 s.data.remove("autoExit");s.commit();s.data=null;s.start();Test.assertEqual(s.number("autoExit"),0);Test.assertEqual(s.xp(),expected);
 for(var i=0;i<5;i++){s.data["autoExit"]=[60,300,900,3600,0][i];s.commit();s.data=null;s.start();Test.assertEqual(BeastInactivity.choice(s.number("autoExit")),i);}
 var legacy=new PersistencePet();legacy.store.memory={"birth"=>legacy.today(),"birthEpoch"=>legacy.now()-86400};legacy.start();Test.assertEqual(legacy.number("autoExit"),0);return true;
}
(:test)
function inactivityBoundaryTest(logger){
 for(var i=0;i<4;i++){var s=PersistenceSupport.fixture(false);s.data["autoExit"]=[60,300,900,3600][i];s.commit();var view=new IdlePet(s);var idle=IdleSupport.bind(view);
  var writes=s.store.writes;idle.ms=s.number("autoExit")*1000-1;idle.expired();Test.assert(!view.exited);Test.assertEqual(s.store.writes,writes);
  idle.ms++;idle.expired();Test.assert(view.exited);Test.assert(idle.timer==null);Test.assertEqual(s.store.writes,writes);IdleSupport.done(view);
 }return true;
}
(:test)
function inactivityOffAndInputTest(logger){
 var s=PersistenceSupport.fixture(false);var view=new IdlePet(s);s.data["autoExit"]=0;var idle=IdleSupport.bind(view);Test.assert(idle.timer==null);idle.ms=7200000;idle.expired();Test.assert(!view.exited);
 s.data["autoExit"]=60;idle.update(view);var input=new TekuTekuBeastInput(view);view.openMenu("Settings");view.selection=7;idle.ms+=59000;input.onSelect();Test.assertEqual(idle.delay,60000);
 idle.ms+=59000;input.onNextPage();Test.assertEqual(idle.delay,60000);idle.ms+=59000;input.onPreviousPage();Test.assertEqual(idle.delay,60000);
 idle.ms+=59000;input.onTap(new RecoveryTap());Test.assertEqual(idle.delay,60000);idle.ms+=59999;idle.expired();Test.assert(!view.exited);idle.ms++;idle.expired();Test.assert(view.exited);IdleSupport.done(view);return true;
}
(:test)
function inactivityAutomaticEventsTest(logger){
 var s=PersistenceSupport.fixture(false);s.data["autoExit"]=60;var view=new IdlePet(s);var idle=IdleSupport.bind(view);view.menu="Settings";view.updateRows();
 for(var i=1;i<12;i++){idle.ms=i*5000;view.safeRefresh();}Test.assertEqual(idle.last,0);idle.ms=60000;idle.expired();Test.assert(view.exited);IdleSupport.done(view);return true;
}
(:test)
function inactivitySettingsTest(logger){
 var s=PersistenceSupport.fixture(false);var view=new IdlePet(s);var idle=IdleSupport.bind(view);view.openMenu("Settings");Test.assertEqual(view.rows[11],"Auto-exit");view.selection=11;new TekuTekuBeastInput(view).onSelect();
 Test.assertEqual(view.selection,1);Test.assertEqual(view.rows.size(),5);Test.assertEqual(view.rows[0],"1 minute");Test.assertEqual(view.rows[4],"Off");
 for(var i=0;i<5;i++){view.openMenu("Auto-exit");view.selection=i;view.perform("select",null);Test.assertEqual(s.number("autoExit"),[60,300,900,3600,0][i]);Test.assertEqual(PersistenceSupport.diskValue(s)["autoExit"],s.number("autoExit"));}
 view.openMenu("Auto-exit");view.perform("back",null);Test.assert(view.menu.equals("Settings"));IdleSupport.done(view);return true;
}
(:test)
function inactivityGamesProtectedTest(logger){
 for(var k=0;k<3;k++){var s=ForegroundSupport.pet();s.data["autoExit"]=60;var game=new IdleGame(s,k);game.begin();var idle=IdleSupport.bind(game);Test.assert(idle.suspended);Test.assert(idle.timer==null);
  idle.ms=3600000;idle.expired();Test.assert(!game.exited);var elapsed=game.elapsed;game.perform("back",null);idle.update(game);Test.assert(!idle.suspended);Test.assertEqual(idle.delay,60000);
  idle.ms+=60000;idle.expired();Test.assert(game.exited);var r=GenerationSupport.reload(s);Test.assertEqual(r.data["sessions"][k]["elapsed"],elapsed);Test.assertEqual(r.data["gameClaims"][k],0);Test.assertEqual(r.number("adventure"),k==2?2:3);IdleSupport.done(game);
 }return true;
}
(:test)
function inactivityCountdownAndFeedbackTest(logger){
 var s=ForegroundSupport.pet();s.data["autoExit"]=60;var game=new IdleGame(s,1);var idle=IdleSupport.bind(game);game.resumeTicks=3;idle.update(game);Test.assert(idle.suspended);idle.ms=100000;game.resumeTicks=0;idle.update(game);Test.assertEqual(idle.last,0);Test.assert(idle.delay<=0);idle.expired();Test.assert(game.exited);IdleSupport.done(game);
 for(var late=0;late<2;late++){
  var view=new IdlePet(s);idle=IdleSupport.bind(view);view.noticeTicks=12;idle.update(view);Test.assert(idle.suspended);
  idle.ms=late==0?40000:100000;view.noticeTicks=0;idle.update(view);Test.assertEqual(idle.last,0);Test.assertEqual(idle.delay,60000-idle.ms);Test.assert(!view.exited);
  if(late==0){idle.expired();Test.assert(!view.exited);idle.ms=60000;}idle.expired();Test.assertEqual(view.exits,1);idle.expired();Test.assertEqual(view.exits,1);IdleSupport.done(view);
 }return true;
}

(:test)
function inactivityBattleProtectedTest(logger){
 var s=ForegroundSupport.pet();s.data["autoExit"]=60;var view=new IdleBattle(s);view.battleVisible=true;view.selectAction();var idle=IdleSupport.bind(view);Test.assert(view.battle!=null);Test.assert(idle.suspended);
 idle.ms=3600000;idle.expired();Test.assert(!view.exited);view.perform("back",null);idle.update(view);Test.assertEqual(idle.delay,60000);var expected=s.store.copy(Storage.getValue("battle.v1"));
 idle.ms+=60000;idle.expired();Test.assert(view.exited);Test.assert(s.store.same(expected,Storage.getValue("battle.v1")));IdleSupport.done(view);return true;
}
(:test)
function inactivityFailureRecoveryTest(logger){
 for(var k=0;k<3;k++){var s=ForegroundSupport.pet();s.data["autoExit"]=60;var game=new IdleGame(s,k);game.begin();game.paused=true;game.elapsed=7;var idle=IdleSupport.bind(game);var before=s.store.copy(Storage.getValue("v4"));s.store.failWrite=true;
  idle.ms=60000;idle.expired();Test.assert(!game.exited);Test.assert(s.storagePaused);Test.assert(s.pendingSession!=null);Test.assert(s.store.same(before,Storage.getValue("v4")));var attempts=s.store.attempts;
  idle.ms+=60000;idle.expired();game.safeRefresh();Test.assertEqual(s.store.attempts,attempts);s.store.failWrite=false;new TekuTekuBeastInput(game).onSelect();Test.assert(!s.storagePaused);Test.assertEqual(game.elapsed,7);Test.assert(game.paused);Test.assertEqual(idle.delay,60000);
  idle.ms+=60000;idle.expired();Test.assert(game.exited);var r=GenerationSupport.reload(s);Test.assertEqual(r.data["sessions"][k]["elapsed"],7);Test.assertEqual(r.data["gameClaims"][k],0);IdleSupport.done(game);
 }return true;
}
(:test)
function inactivityLifecycleTest(logger){
 var s=PersistenceSupport.fixture(false);s.data["autoExit"]=60;var view=new IdlePet(s);var idle=IdleSupport.bind(view);idle.ms=59000;Application.getApp().onInactive(null);Test.assert(idle.timer==null);Test.assert(idle.view==null);idle.ms=3600000;idle.expired();Test.assert(!view.exited);
 view.onShow();Test.assertEqual(idle.last,3600000);idle.ms+=59999;idle.expired();Test.assert(!view.exited);idle.ms++;idle.expired();Test.assert(view.exited);IdleSupport.done(view);return true;
}
(:test)
function inactivityWrapAndWritesTest(logger){
 var s=PersistenceSupport.fixture(false);s.data["autoExit"]=3600;var view=new IdlePet(s);var idle=IdleSupport.bind(view);var writes=s.store.writes;var arms=idle.arms;
 for(var i=1;i<100;i++){idle.ms=i*20;idle.update(view);}Test.assertEqual(idle.arms,arms);Test.assertEqual(s.store.writes,writes);
 idle.ms=-10;idle.expired();Test.assert(!view.exited);Test.assertEqual(idle.last,-10);Test.assertEqual(s.store.writes,writes);IdleSupport.done(view);return true;
}
(:test)
function inactivityNavigationTest(logger){
 var s=PersistenceSupport.fixture(false);s.data["autoExit"]=60;var root=new IdlePet(s);var idle=IdleSupport.bind(root);idle.ms=59000;root.perform("activity",null);root.onHide();Test.assert(idle.timer==null);var game=new IdleGame(s,0);game.onShow();Test.assertEqual(idle.last,59000);idle.ms+=60000;idle.expired();Test.assert(game.exited);IdleSupport.done(game);return true;
}

(:test)
function inactivityIdleWriteFrequencyTest(logger){
 var s=PersistenceSupport.fixture(false);s.data["autoExit"]=3600;s.commit();s.store.reset();var view=new IdlePet(s);var idle=IdleSupport.bind(view);
 for(var i=1;i<=180;i++){s.clock+=20;s.syncIdle();idle.ms=i*20000;idle.update(view);if(i==45){Test.assertEqual(s.store.writes,30);} }
 Test.assertEqual(s.store.writes,120);Test.assertEqual(idle.arms,1);idle.expired();Test.assert(view.exited);Test.assertEqual(s.store.writes,120);IdleSupport.done(view);return true;
}
(:test)
function inactivityPetSaveFailureTest(logger){
 var s=ForegroundSupport.pet();s.data["autoExit"]=60;s.commit();s.clock+=20;s.syncIdle();var view=new IdlePet(s);var idle=IdleSupport.bind(view);var durable=s.store.copy(Storage.getValue("v4"));s.store.failWrite=true;
 idle.ms=60000;idle.expired();Test.assert(!view.exited);Test.assert(s.storagePaused);Test.assert(s.store.same(durable,Storage.getValue("v4")));var attempts=s.store.attempts;
 idle.ms+=60000;idle.expired();view.safeRefresh();Test.assertEqual(s.store.attempts,attempts);s.store.failWrite=false;new TekuTekuBeastInput(view).onSelect();Test.assert(!s.storagePaused);Test.assertEqual(Storage.getValue("v4")["lastGrowth"],s.now());IdleSupport.done(view);return true;
}
(:test)
function inactivityFriendWaitingTest(logger){
 var s=ForegroundSupport.pet();s.data["autoExit"]=60;var view=new BeastFriendView(s);var idle=IdleSupport.bind(view);Test.assert(!idle.suspended);
 view.link=new BeastFriendLink(true,1,2,BeastFriendModel.snapshot(s),0);idle.update(view);Test.assert(idle.suspended);Test.assert(idle.timer==null);
 view.link.fail("QA CLOSED",0);idle.update(view);Test.assert(!idle.suspended);Test.assertEqual(idle.delay,60000);IdleSupport.done(view);return true;
}
// Normal VM, real one-minute one-shot timer and real System.exit (isolated QA UUID).
class InactivitySmoke extends TekuTekuBeastView {
 var began=0;var samples=0;var peak=0;var total=0;
 function initialize(s){TekuTekuBeastView.initialize();beast=s;}
 function onShow(){
  var probe=new BeastInactivity();probe.arm(1);Test.assert(probe.timer!=null);probe.stop();Toybox.System.println("INACTIVITY_MIN_TIMER_OK");
  var before=Toybox.System.getSystemStats().usedMemory;Application.getApp().inactivity=new BeastInactivity();var after=Toybox.System.getSystemStats().usedMemory;
  Toybox.System.println("INACTIVITY_OBJECT_BYTES="+(after-before));began=Toybox.System.getTimer();TekuTekuBeastView.onShow();openMenu("Auto-exit");beast.store.reset();
 }
 function sample(){var stats=Toybox.System.getSystemStats();peak=peak>stats.usedMemory?peak:stats.usedMemory;total=stats.totalMemory;}
 function refresh() as Void {selection=samples%5;beast.clock+=5;TekuTekuBeastView.refresh();samples++;sample();}
 function onUpdate(dc){TekuTekuBeastView.onUpdate(dc);sample();}
 function exitApplication(){
  var saved=Storage.getValue("v4");var elapsed=Toybox.System.getTimer()-began;
  Toybox.System.println("INACTIVITY_CHECKPOINT elapsedMs="+elapsed+" lastGrowth="+saved["lastGrowth"]+" now="+beast.now()+" saved="+beast.store.same(saved,beast.data));
  Test.assert(beast.store.same(saved,beast.data));Test.assert(elapsed>=60000);sample();
  Toybox.System.println("INACTIVITY_SMOKE_OK elapsedMs="+elapsed+" refreshes="+samples+" writes="+beast.store.writes+" used="+peak+" total="+total+" headroom="+(total-peak));Toybox.System.exit();
 }
}

(:test)
function inactivityRepeatedShowTest(logger){
 var s=PersistenceSupport.fixture(false);s.data["autoExit"]=60;s.commit();var view=new IdlePet(s);var idle=IdleSupport.bind(view);idle.ms=59000;
 view.onShow();Test.assertEqual(idle.last,0);idle.ms=60000;idle.expired();Test.assert(view.exited);IdleSupport.done(view);return true;
}

(:test)
function inactivityReadFailureStopsTimerTest(logger){
 var s=ForegroundSupport.pet();s.data["autoExit"]=60;s.commit();var view=new IdlePet(s);var idle=IdleSupport.bind(view);s.store.failRead=true;view.perform("storage",null);
 Test.assert(s.storagePaused);Test.assert(s.data==null);Test.assert(idle.timer==null);var reads=s.store.petReads;idle.ms=120000;idle.expired();Test.assertEqual(s.store.petReads,reads);Test.assert(!view.exited);
 s.store.failRead=false;new TekuTekuBeastInput(view).onSelect();Test.assert(!s.storagePaused);Test.assertEqual(idle.delay,60000);IdleSupport.done(view);return true;
}

(:test)
function inactivityAutomaticNavigationTest(logger){
 var s=PersistenceSupport.fixture(false);s.data["autoExit"]=60;s.commit();var root=new IdlePet(s);var idle=IdleSupport.bind(root);idle.ms=30000;root.onHide();
 var next=new IdleGame(s,0);next.onShow();Test.assertEqual(idle.last,0);idle.ms=60000;idle.expired();Test.assert(next.exited);IdleSupport.done(next);return true;
}

class HiddenIdlePet extends IdlePet {
 function initialize(s){IdlePet.initialize(s);}
 function drawCore(dc){}
 function refresh() as Void {}
}
(:test)
function inactivityLateHiddenCallbackTest(logger){
 var s=PersistenceSupport.fixture(false);s.data["autoExit"]=60;s.commit();var view=new HiddenIdlePet(s);var idle=IdleSupport.bind(view);
 Application.getApp().onInactive(null);idle.ms=120000;view.onUpdate(null);view.safeRefresh();view.perform("storage",null);
 Test.assert(idle.timer==null);Test.assert(idle.view==null);idle.expired();Test.assert(!view.exited);
 view.onShow();Test.assertEqual(idle.delay,60000);Test.assertEqual(idle.last,120000);IdleSupport.done(view);return true;
}

// Both paths execute production refresh -> syncIdle -> feedback -> scheduler.
function automaticFeedback(evolve,start,press,off){
 var s=PersistenceSupport.fixture(false);s.data["autoExit"]=off?0:60;s.data["motion"]=2;s.data["haptics"]=0;
 if(evolve){s.data["birthEpoch"]=s.now()-3*86400;s.data["baseGrowth"]=19999l;}
 else{s.data["poopDue"]=s.now()+1;}
 s.commit();var view=new IdlePet(s);var idle=IdleSupport.bind(view);var stage=s.stage();s.clock+=20;view.timerPeriod=250;view.tick=79;idle.ms=start;
 view.safeRefresh();Test.assert(idle.suspended);Test.assert(idle.timer==null);Test.assert(!view.exited);Test.assertEqual(idle.last,0);
 if(evolve){Test.assert(s.stage()>stage);Test.assert(view.animation.equals("evolve"));Test.assertEqual(s.number("evolutionPending"),0);}
 else{Test.assertEqual(s.number("poop"),1);Test.assert(view.animation.equals("hop"));}
 var frames=0;var baseline=0;
 while(view.autoExitProtected() && frames<20){
  idle.ms+=250;if(press && frames==1){view.perform("activity",null);baseline=idle.ms;}
  view.safeRefresh();frames++;Test.assert(!view.exited);
 }
 Test.assert(!view.autoExitProtected());Test.assertEqual(idle.last,baseline);
 if(off){idle.ms+=3600000;idle.expired();Test.assert(!view.exited);Test.assert(idle.timer==null);}
 else{
  Test.assertEqual(idle.delay,60000-(idle.ms-baseline));idle.expired();
  if(idle.ms-baseline<60000){Test.assert(!view.exited);idle.ms=baseline+60000;idle.expired();}
  Test.assertEqual(view.exits,1);var writes=s.store.writes;idle.expired();Test.assertEqual(view.exits,1);Test.assertEqual(s.store.writes,writes);
  Test.assert(s.store.same(PersistenceSupport.diskValue(s),s.data));
 }
 IdleSupport.done(view);return true;
}
(:test)
function inactivityAutomaticPoopFeedbackTest(logger){automaticFeedback(false,40000,false,false);automaticFeedback(false,59000,false,false);automaticFeedback(false,59000,true,false);return automaticFeedback(false,59000,false,true);}
(:test)
function inactivityAutomaticEvolutionFeedbackTest(logger){automaticFeedback(true,40000,false,false);automaticFeedback(true,59000,false,false);automaticFeedback(true,59000,true,false);return automaticFeedback(true,59000,false,true);}
(:test)
function inactivityDelayedCallbackDeadlineTest(logger){
 var s=PersistenceSupport.fixture(false);s.data["autoExit"]=60;s.commit();var oldView=new IdlePet(s);var idle=IdleSupport.bind(oldView);var delayed=idle.method(:expired);
 idle.ms=59000;oldView.perform("activity",null);idle.ms=60000;delayed.invoke();Test.assert(!oldView.exited);Test.assertEqual(idle.last,59000);Test.assertEqual(idle.delay,59000);
 oldView.openMenu("Auto-exit");oldView.selection=4;oldView.perform("select",null);delayed.invoke();Test.assert(idle.timer==null);Test.assert(!oldView.exited);
 idle.ms=70000;oldView.openMenu("Auto-exit");oldView.selection=0;oldView.perform("select",null);oldView.onHide();var current=new IdlePet(s);current.onShow();idle.ms=71000;delayed.invoke();Test.assertEqual(idle.last,70000);Test.assert(!current.exited);Test.assertEqual(oldView.exits,0);
 idle.ms=130000;delayed.invoke();Test.assertEqual(current.exits,1);var writes=s.store.writes;delayed.invoke();Test.assertEqual(current.exits,1);Test.assertEqual(s.store.writes,writes);Test.assert(idle.timer==null);IdleSupport.done(current);return true;
}
// Normal VM: real automatic evolution feedback crosses the one-minute deadline.
class InactivityProtectionSmoke extends InactivitySmoke {
 var baseClock;var fired=false;var baseline;
 function initialize(s){InactivitySmoke.initialize(s);baseClock=s.clock;}
 function onShow(){InactivitySmoke.onShow();menu=null;tunePetTimer();baseline=Application.getApp().inactivity.last;}
 function refresh() as Void {
  var elapsed=Toybox.System.getTimer()-began;beast.clock=baseClock+(elapsed/1000).toNumber();
  if(!fired && elapsed>=59000){beast.data["birthEpoch"]=beast.now()-3*86400;beast.data["baseGrowth"]=19999l;beast.data["lastGrowth"]=beast.now()-20;beast.syncIdle();fired=true;}
  TekuTekuBeastView.refresh();samples++;sample();Test.assertEqual(Application.getApp().inactivity.last,baseline);
 }
 function exitApplication(){var elapsed=Toybox.System.getTimer()-began;Test.assert(fired);Test.assert(!autoExitProtected());Test.assert(elapsed>=60000 && elapsed<70000);Toybox.System.println("INACTIVITY_PROTECTED_EXIT_OK elapsedMs="+elapsed);InactivitySmoke.exitApplication();}
}

class IdleRadio {
 var opened=true;var status="QA";
 function initialize(){}
 function send(packet){}
 function close(){opened=false;}
}
class IdleFriend extends BeastFriendView {
 var elapsed=0;var exits=0;
 function initialize(s){BeastFriendView.initialize(s);}
 function battleClock(){return elapsed;}
 function exitApplication(){exits++;}
}
(:test)
function inactivityFriendResultGraceTest(logger){
 var s=ForegroundSupport.pet();s.data["autoExit"]=60;s.commit();var view=new IdleFriend(s);view.link=new BeastFriendLink(true,1,2,BeastFriendModel.snapshot(s),0);view.link.phase="RESULT";view.radio=new IdleRadio();view.visible=true;view.resultAt=1000;
 var battle=s.store.copy(Storage.getValue("battle.v1"));var idle=IdleSupport.bind(view);idle.ms=70000;view.elapsed=8999;view.safeRefresh();idle.expired();Test.assertEqual(view.exits,0);Test.assert(view.radio.opened);Test.assertEqual(idle.last,0);
 view.elapsed=9000;view.safeRefresh();Test.assert(!view.radio.opened);Test.assertEqual(idle.last,0);idle.expired();Test.assertEqual(view.exits,1);idle.expired();Test.assertEqual(view.exits,1);Test.assert(s.store.same(battle,Storage.getValue("battle.v1")));IdleSupport.done(view);return true;
}

}
class InactivitySmokeApp extends PersistenceApp {
 function getInitialView(){var s=PersistenceSupport.fixture(true);s.data["autoExit"]=60;s.data["motion"]=2;s.data["haptics"]=0;s.commit();return [new InactivityQA.InactivityProtectionSmoke(s)];}
}
