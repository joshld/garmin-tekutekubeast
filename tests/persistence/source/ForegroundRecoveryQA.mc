using Toybox.Test;using Toybox.Application;using Toybox.Application.Storage;
class ForegroundStore extends PersistenceStore {
 var attempts=0;var petReads=0;var failRead=false;var failBattle=false;var failGlance=false;
 function initialize(){PersistenceStore.initialize();}
 function read(key){if(key.equals("v4")){petReads++;if(failRead){throw new Toybox.Lang.StorageFullException("QA unavailable read");}}return PersistenceStore.read(key);}
 function write(key,value){attempts++;if(failGlance && key.equals("glance.v1")){throw new Toybox.Lang.StorageFullException("QA post-v4 cache failure");}if(failBattle && key.equals("battle.v1")){throw new Toybox.Lang.StorageFullException("QA battle write");}return PersistenceStore.write(key,value);}
}
module ForegroundSupport {
 function pet(){var s=ReliabilityAuditSupport.pet();var store=new ForegroundStore();store.canonical=store.copy(s.data);s.store=store;return s;}
}
class RecoveryDc {
 var lines=[];
 function initialize(){}
 function getWidth(){return 240;}
 function getHeight(){return 240;}
 function getTextWidthInPixels(text,font){return text.length()*6;}
 function getFontHeight(font){return 14;}
 function setColor(a,b){}
 function clear(){}
 function drawText(x,y,font,text,align){lines.add(text);Test.assert(y>=0 && y<240);}
}
class ProductionRecoveryApp extends PersistenceApp {
 function getInitialView(){return [new ProductionRecoveryProbe()];}
}
// Real timer -> production input/lifecycle/paint. No QA exception catcher.
class ProductionRecoveryProbe extends Toybox.WatchUi.View {
 var game;var timer;var stage=0;var before;var peak=0;var budget=0;
 function initialize(){Toybox.WatchUi.View.initialize();var s=ForegroundSupport.pet();game=new BeastGameView(s,1);s.store.failWrite=true;before=s.store.copy(Storage.getValue("v4"));}
 function onShow(){timer=new Toybox.Timer.Timer();timer.start(method(:trigger),150,true);}
 function onHide(){if(timer!=null){timer.stop();timer=null;}game.onHide();}
 function sample(){var stats=Toybox.System.getSystemStats();peak=peak>stats.usedMemory?peak:stats.usedMemory;budget=stats.totalMemory;}
 function trigger(){
  sample();var input=new TekuTekuBeastInput(game);var s=game.beast;
  if(stage==0){Toybox.System.println("PRODUCTION_BEFORE_INPUT");input.onSelect();Test.assert(s.storagePaused);Test.assertEqual(s.store.attempts,1);Toybox.System.println("PRODUCTION_AFTER_INPUT");}
  else if(stage==1){for(var i=0;i<10;i++){game.safeRefresh();game.onHide();game.onShow();}Test.assertEqual(s.store.attempts,1);input.onSelect();Test.assertEqual(s.store.attempts,2);Test.assert(s.store.same(before,Storage.getValue("v4")));}
  else{SessionInterleaveSupport.background(s,4000,0);s.store.failWrite=false;input.onSelect();Test.assert(!s.storagePaused);Test.assert(s.pendingSession==null);Test.assertEqual(s.xp(),4000l);Test.assert(game.session!=null);sample();Toybox.System.println("PRODUCTION_MEMORY used="+peak+" total="+budget+" headroom="+(budget-peak));Toybox.System.println("PRODUCTION_RECOVERY_OK");onHide();Toybox.System.exit();}
  stage++;
 }
 function onUpdate(dc){game.onUpdate(dc);sample();}
}
(:test)
function foregroundPersistentFailureTest(logger){
 for(var kind=0;kind<3;kind++){
  var s=ForegroundSupport.pet();var game=new BeastGameView(s,kind);var input=new TekuTekuBeastInput(game);var expected=s.store.copy(Storage.getValue("v4"));s.store.failWrite=true;
  input.onSelect();Test.assert(s.storagePaused);Test.assert(s.pendingSession!=null);Test.assertEqual(s.store.attempts,1);
  for(var i=0;i<8;i++){game.safeRefresh();game.onShow();game.onHide();new SessionNotificationHarness(game).onStorageChanged();game.onUpdate(new RecoveryDc());}
  Test.assertEqual(s.store.attempts,1);Test.assert(s.store.same(expected,Storage.getValue("v4")));
  input.onSelect();Test.assertEqual(s.store.attempts,2);Test.assert(s.storagePaused);
  SessionInterleaveSupport.background(s,4000,0);s.store.failWrite=false;input.onSelect();Test.assert(!s.storagePaused);Test.assert(s.pendingSession==null);Test.assert(game.session!=null);Test.assert(game.paused);Test.assertEqual(s.xp(),4000l);Test.assertEqual(s.number("adventure"),kind==2?2:3);game.onHide();
 }
 return true;
}
(:test)
function foregroundCheckpointRecoveryTest(logger){
 for(var kind=0;kind<3;kind++){
  var s=ForegroundSupport.pet();var game=new BeastGameView(s,kind);game.begin();game.elapsed=7;var old=game.callbacks;var initial=s.store.attempts;s.store.failWrite=true;
  game.onHide();Test.assert(s.storagePaused);Test.assert(game.refresher==null);Test.assertEqual(s.store.attempts,initial+1);
  game.onShow();game.safeRefresh();Test.assertEqual(s.store.attempts,initial+1);
  SessionInterleaveSupport.background(s,4000,0);s.store.failWrite=false;new TekuTekuBeastInput(game).onSelect();Test.assert(!s.storagePaused);Test.assertEqual(game.elapsed,7);
  var expected=s.store.copy(Storage.getValue("v4"));old.finish(true);Test.assert(s.store.same(expected,Storage.getValue("v4")));var r=GenerationSupport.reload(s);Test.assertEqual(r.xp(),4000l);Test.assertEqual(r.data["sessions"][kind]["elapsed"],7);game.onHide();
 }
 return true;
}
(:test)
function foregroundCompletionRecoveryTest(logger){
 for(var kind=0;kind<3;kind++){
  var s=ForegroundSupport.pet();var game=new BeastGameView(s,kind);game.begin();var owner=game.callbacks;var id=game.session["id"];s.store.failWrite=true;
  owner.finish(true);Test.assert(s.storagePaused);Test.assert(s.pendingSession!=null);var attempts=s.store.attempts;
  owner.finish(true);game.safeRefresh();game.onUpdate(new RecoveryDc());Test.assertEqual(s.store.attempts,attempts);
  SessionInterleaveSupport.background(s,5000,0);s.store.failWrite=false;new TekuTekuBeastInput(game).onSelect();Test.assert(!s.storagePaused);var r=GenerationSupport.reload(s);Test.assertEqual(r.data["gameClaims"][kind],id);Test.assert(r.data["sessions"][kind]==null);Test.assertEqual(r.xp(),5000l);
  var expected=s.store.copy(Storage.getValue("v4"));owner.finish(true);Test.assert(s.store.same(expected,Storage.getValue("v4")));game.onHide();
 }
 return true;
}
(:test)
function foregroundReadAndReloadTest(logger){
 var s=ForegroundSupport.pet();var game=new BeastGameView(s,1);game.begin();var reads=s.store.petReads;game.onShow();Test.assertEqual(s.store.petReads-reads,1);game.onHide();
 s.store.failRead=true;game.onShow();Test.assert(s.storagePaused);reads=s.store.petReads;
 for(var i=0;i<8;i++){game.onUpdate(new RecoveryDc());game.safeRefresh();game.onShow();}Test.assertEqual(s.store.petReads,reads);
 new TekuTekuBeastInput(game).onSelect();Test.assertEqual(s.store.petReads,reads+1);Test.assert(s.storagePaused);
 s.store.failRead=false;new TekuTekuBeastInput(game).onSelect();Test.assert(!s.storagePaused);game.onHide();return true;
}
class BadForegroundView extends TekuTekuBeastView {
 function initialize(s){TekuTekuBeastView.initialize();beast=s;}
 function selectAction(){throw new Toybox.Lang.InvalidValueException("QA programming error");}
}
(:test)
function foregroundNonStorageErrorTest(logger){var s=ForegroundSupport.pet();var caught=false;try{new TekuTekuBeastInput(new BadForegroundView(s)).onSelect();}catch(e instanceof Toybox.Lang.InvalidValueException){caught=true;}Test.assert(caught);Test.assert(!s.storagePaused);return true;}
(:test)
function foregroundBattleRecoveryTest(logger){
 var s=ForegroundSupport.pet();var game=new BeastBattleView(s);game.battleVisible=true;var input=new TekuTekuBeastInput(game);input.onSelect();Test.assert(game.battle!=null);var expected=s.store.copy(Storage.getValue("battle.v1"));s.store.failBattle=true;
 input.onSelect();Test.assert(s.storagePaused);Test.assert(game.battleTimer==null);Test.assert(s.store.same(expected,Storage.getValue("battle.v1")));var attempts=s.store.attempts;game.onShow();game.safeRefresh();Test.assertEqual(s.store.attempts,attempts);
 s.store.failBattle=false;input.onSelect();Test.assert(!s.storagePaused);Test.assert(s.store.same(expected["active"],game.fight.data["active"]));game.onHide();return true;
}

class ForegroundNavigationGame extends BeastGameView {
 function initialize(s){BeastGameView.initialize(s,1);}
 function leaveGameMenu(){petView.onShow();}
}
(:test)
function foregroundNavigationRecoveryTest(logger){
 var s=ForegroundSupport.pet();var parent=new TekuTekuBeastView();parent.beast=s;
 var game=new ForegroundNavigationGame(s);game.petView=parent;var input=new TekuTekuBeastInput(game);s.store.failWrite=true;input.onSelect();Test.assert(s.storagePaused);var attempts=s.store.attempts;
 input.onNextPage();Test.assertEqual(game.recoveryChoice,1);input.onSelect();Test.assertEqual(Application.getApp().activeView,parent);Test.assertEqual(s.store.attempts,attempts);parent.onUpdate(new RecoveryDc());
 s.store.failWrite=false;new TekuTekuBeastInput(parent).onTap(new RecoveryTap());Test.assert(!s.storagePaused);Test.assert(s.pendingSession==null);Test.assert(s.data["sessions"][1]!=null);parent.onHide();Application.getApp().activeView=null;return true;
}
class RecoveryTap {
 function initialize(){}
 function getCoordinates(){return [120,130];}
}

(:test)
function foregroundPostWriteRecoveryTest(logger){
 for(var kind=0;kind<3;kind++){
  var s=ForegroundSupport.pet();var game=new BeastGameView(s,kind);game.begin();var owner=game.callbacks;var id=game.session["id"];s.store.failGlance=true;
  owner.finish(true);Test.assert(s.storagePaused);Test.assert(s.pendingSession!=null);Test.assertEqual(Storage.getValue("v4")["gameClaims"][kind],id);
  SessionInterleaveSupport.background(s,4000,0);var expected=s.store.copy(Storage.getValue("v4"));s.store.failGlance=false;new TekuTekuBeastInput(game).onSelect();Test.assert(!s.storagePaused);
  var r=GenerationSupport.reload(s);var keys=["xp","days","counts","gameClaims","sessions","games","items","adventure","energy","friendship","careGrowth","careToday","personality","affinity"];
  for(var i=0;i<keys.size();i++){Test.assert(s.store.same(expected[keys[i]],r.data[keys[i]]));}
  var writes=s.store.writes;owner.finish(true);Test.assertEqual(s.store.writes,writes);game.onHide();
 }
 return true;
}

(:test)
function foregroundFriendIsolationTest(logger){
 var s=ForegroundSupport.pet();var friend=new BeastFriendView(s);var before=s.store.copy(Storage.getValue("battle.v1"));s.storagePaused=true;
 new TekuTekuBeastInput(friend).onSelect();Test.assert(!s.storagePaused);Test.assert(friend.fight==null);Test.assert(s.store.same(before,Storage.getValue("battle.v1")));friend.onHide();return true;
}
