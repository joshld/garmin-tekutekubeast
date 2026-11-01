using Toybox.Test;using Toybox.Application;using Toybox.Application.Storage;using Toybox.WatchUi;using Toybox.System;
// Isolated QA application: native tests and accelerated rendered idle smoke.
class PersistenceStore extends BeastStore {
 var pets=0;var glances=0;var failWrite=false;var failCopy=false;
 function initialize(){BeastStore.initialize();}
 function write(key,value){if(failWrite && key.equals("v4")){throw new Toybox.Lang.InvalidValueException("QA write failure");}var result=BeastStore.write(key,value);if(result){if(key.equals("v4")){pets++;}if(key.equals("glance.v1")){glances++;}}return result;}
 function copy(value){if(failCopy){throw new Toybox.Lang.InvalidValueException("QA post-write copy failure");}return BeastStore.copy(value);}
 function reset(){pets=0;glances=0;writes=0;skipped=0;}
}
class PersistencePet extends TekuTekuBeastState {
 var clock=1792108800l;var suppliedSteps=-1;
 function initialize(){TekuTekuBeastState.initialize();skipWatch=true;}
 function realNow(){return clock;}
 function syncToday(){if(suppliedSteps>=0){syncActivity(suppliedSteps,null,null);}else{TekuTekuBeastState.syncToday();}}
}
module PersistenceSupport {
 function fixture(disk){
  var s=new PersistencePet();s.store.memory={};s.start();var t=s.now();
  s.data["birthEpoch"]=t-86400;s.data["stageFloor"]=1;s.data["baseGrowth"]=5000l;s.data["careGrowth"]=0l;s.data["activityBonus"]=0l;s.data["petXpBaseline"]=s.xp();s.data["family"]=0;
  s.data["lastGrowth"]=t;s.data["growthRemainder"]=0l;s.data["lastCare"]=t;s.data["careAt"]=t;s.data["sleepMode"]=2;s.data["sleepUntil"]=0l;s.data["motion"]=0;s.data["poop"]=0;s.data["poopSlots"]=0;s.data["poopDue"]=t+172800;s.data["digestion"]=[0l,0,0l,0,0l,0,0l,0];s.data["day"]=s.today();s.data["fullness"]=80;s.data["happiness"]=80;s.data["energy"]=80;s.data["evolutionPending"]=0;
  s.store=new PersistenceStore();if(!disk){s.store.memory={};}s.commit();s.store.reset();return s;
 }
 function diskValue(s){return s.store.memory==null?Storage.getValue("v4"):s.store.memory["v4"];}
}
(:test)
function persistenceMinuteFrequencyTest(logger){
 var s=PersistenceSupport.fixture(false);var control=PersistenceSupport.fixture(false);
 for(var i=0;i<9;i++){s.clock+=20;s.syncIdle();control.clock+=20;control.syncToday();}
 Test.assertEqual(s.store.pets,3);Test.assertEqual(s.store.glances,3);Test.assertEqual(control.store.pets,9);
 Test.assertEqual(s.number("baseGrowth"),control.number("baseGrowth"));Test.assertEqual(s.number("growthRemainder"),control.number("growthRemainder"));
 var writes=s.store.writes;s.commit();s.syncIdle();Test.assertEqual(s.store.writes,writes);return true;
}
(:test)
function persistenceCriticalActionsAndStepsTest(logger){
 var s=PersistenceSupport.fixture(false);s.clock+=20;s.syncIdle();Test.assertEqual(s.store.writes,0);
 s.skipWatch=false;s.suppliedSteps=100;s.syncIdle();Test.assertEqual(PersistenceSupport.diskValue(s)["xp"],100l);var credited=s.xp();s.syncIdle();Test.assertEqual(s.xp(),credited);
 s.skipWatch=true;s.suppliedSteps=-1;Test.assert(s.pat());Test.assertEqual(PersistenceSupport.diskValue(s)["friendship"],s.friendship());
 var game=s.beginSession(1);Test.assert(game!=null);Test.assertEqual(PersistenceSupport.diskValue(s)["sessions"][1]["id"],game["id"]);
 game["sequence"]=[0,0,1];Test.assert(s.saveSession(game));Test.assertEqual(PersistenceSupport.diskValue(s)["sessions"][1]["sequence"].size(),3);
 var result=s.completeSession(game,true);Test.assert(PersistenceSupport.diskValue(s)["sessions"][1]==null);var growth=s.growth();s.completeSession(game,true);Test.assertEqual(s.growth(),growth);return true;
}
(:test)
function persistenceReopenAndRecoveryTest(logger){
 var s=PersistenceSupport.fixture(true);var t=s.now();s.clock+=20;s.syncIdle();Test.assertEqual(Storage.getValue("v4")["lastGrowth"],t);
 var reopened=new PersistencePet();reopened.clock=t+40;reopened.start();reopened.syncIdle();Test.assertEqual(reopened.number("baseGrowth"),5005l);reopened.commit();
 var again=new PersistencePet();again.clock=t+40;again.start();again.syncIdle();Test.assertEqual(again.number("baseGrowth"),5005l);Test.assertEqual(again.number("version"),4);Test.assertEqual(again.xp(),s.xp());return true;
}
(:test)
function persistenceLifecycleFlushTest(logger){
 var s=PersistenceSupport.fixture(true);var view=new TekuTekuBeastView();view.beast=s;var app=Application.getApp();app.activeView=view;
 s.clock+=20;s.syncIdle();view.onHide();Test.assertEqual(Storage.getValue("v4")["lastGrowth"],s.now());
 s.clock+=20;s.syncIdle();app.onInactive(null);Test.assertEqual(Storage.getValue("v4")["lastGrowth"],s.now());
 s.clock+=20;s.syncIdle();app.onStop(null);Test.assertEqual(Storage.getValue("v4")["lastGrowth"],s.now());
 var before=s.store.writes;app.onStop(null);Test.assertEqual(s.store.writes,before);app.activeView=null;return true;
}
(:test)
function persistenceEvolutionAndSleepBoundaryTest(logger){
 var s=PersistenceSupport.fixture(false);s.data["birthEpoch"]=s.now()-3*86400;s.data["baseGrowth"]=19999l;s.commit();var stage=s.stage();s.clock+=20;s.syncIdle();Test.assert(s.stage()>stage);Test.assertEqual(PersistenceSupport.diskValue(s)["stageFloor"],s.stage());Test.assertEqual(PersistenceSupport.diskValue(s)["evolutionPending"],1);
 s=PersistenceSupport.fixture(false);s.data["sleepUntil"]=s.now()+30;s.commit();s.store.reset();s.clock+=40;s.syncIdle();Test.assert(s.store.pets>0);Test.assert(!s.isSleeping());Test.assert(!PersistenceSupport.diskValue(s)["cachedMood"].equals("RESTING"));return true;
}
(:test)
function persistenceCareClockAndDevTest(logger){
 var s=PersistenceSupport.fixture(false);s.data["lastCare"]=s.now()-3590;s.data["careAt"]=s.now()-3590;s.commit();s.store.reset();s.clock+=20;s.syncIdle();Test.assert(s.store.pets>0);Test.assertEqual(PersistenceSupport.diskValue(s)["lastCare"],s.number("lastCare"));
 s=PersistenceSupport.fixture(false);var start=s.now();s.clock-=20;s.syncIdle();Test.assertEqual(s.number("baseGrowth"),5000l);s.clock=start+3600;s.syncIdle();Test.assertEqual(s.number("baseGrowth"),5500l);var count=s.store.writes;s.syncIdle();Test.assertEqual(s.store.writes,count);
 var dev=s.enableDev();count=s.store.writes;dev.syncIdle();Test.assertEqual(s.store.writes,count);return true;
}
(:test)
function persistenceFailureRestoresForcePolicyTest(logger){
 for(var mode=0;mode<2;mode++){
  var s=PersistenceSupport.fixture(true);var old=s.now();s.clock+=60;if(mode==0){s.store.failWrite=true;}else{s.store.failCopy=true;}
  var caught=false;try{s.syncIdle();}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);Test.assert(!s.idleSync);Test.assert(s.store.canonical==null);
  Test.assertEqual(Storage.getValue("v4")["lastGrowth"],mode==0?old:s.now());s.store.failWrite=false;s.store.failCopy=false;s.commit();Test.assertEqual(Storage.getValue("v4")["lastGrowth"],s.now());var writes=s.store.writes;s.commit();Test.assertEqual(s.store.writes,writes);
 }return true;
}
(:background,:glance)
class PersistenceApp extends TekuTekuBeastApp {
 function initialize(){TekuTekuBeastApp.initialize();}
 function getInitialView(){return [new PersistenceSmoke(PersistenceSupport.fixture(true))];}
 function onStorageChanged(){}
}
class PersistenceSmoke extends TekuTekuBeastView {
 var callbacks=0;var began=0;
 function initialize(model){TekuTekuBeastView.initialize();beast=model;}
 function onShow(){TekuTekuBeastView.onShow();beast.store.reset();began=System.getTimer();refresher.stop();timerPeriod=5000;refresher.start(method(:refresh),50,true);}
 function refresh() as Void {
  beast.clock+=5;TekuTekuBeastView.refresh();callbacks++;
  if(callbacks==180 || callbacks==720){System.println("PERSIST_IDLE seconds="+(callbacks*5)+" pets="+beast.store.pets+" glance="+beast.store.glances+" writes="+beast.store.writes+" growth="+beast.number("baseGrowth")+" hostMs="+(System.getTimer()-began));}
  if(callbacks==720){beast.clock+=20;beast.syncIdle();var before=beast.store.writes;onHide();System.println("PERSIST_HIDE forcedWrites="+(beast.store.writes-before));System.println("PERSIST_SMOKE_COMPLETE");System.exit();}
 }
}
