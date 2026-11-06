using Toybox.Test;using Toybox.Application.Storage;
// Regression assertions retained from the read-only reliability audit.
// All Storage belongs to the existing isolated QA application.
module ReliabilityAuditSupport {
 function pet(){Storage.deleteValue("battle.v1");var s=PersistenceSupport.fixture(true);s.data["adventure"]=3;s.commit();return s;}
 function failPet(s){s.store.failWrite=true;}
 function restorePet(s){s.store.failWrite=false;}
}
(:test)
function auditSessionBeginRetryDurableTest(logger){
 var all=true;
 for(var kind=0;kind<3;kind++){
  var s=ReliabilityAuditSupport.pet();var disk=s.store.copy(Storage.getValue("v4"));ReliabilityAuditSupport.failPet(s);var caught=false;
  try{s.beginSession(kind);}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);Test.assert(s.store.same(disk,Storage.getValue("v4")));
  ReliabilityAuditSupport.restorePet(s);var session=s.beginSession(kind);var durable=Storage.getValue("v4")["sessions"][kind];
  var ok=durable!=null && durable["id"]==session["id"];logger.debug("AUDIT begin kind="+kind+" durable="+ok+" liveEnergy="+s.number("adventure")+" diskEnergy="+Storage.getValue("v4")["adventure"]);all=all && ok;
 }
 Test.assert(all);return true;
}
(:test)
function auditSessionCheckpointRetryDurableTest(logger){
 var all=true;
 for(var kind=0;kind<3;kind++){
  var s=ReliabilityAuditSupport.pet();var session=s.beginSession(kind);session["round"]=2;session["elapsed"]=7;var before=s.store.copy(Storage.getValue("v4"));ReliabilityAuditSupport.failPet(s);var caught=false;
  try{s.saveSession(session);}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);Test.assert(s.store.same(before,Storage.getValue("v4")));
  ReliabilityAuditSupport.restorePet(s);var accepted=s.saveSession(session);var saved=Storage.getValue("v4")["sessions"][kind];
  var ok=accepted && saved["round"]==2 && saved["elapsed"]==7;logger.debug("AUDIT checkpoint kind="+kind+" accepted="+accepted+" diskRound="+saved["round"]+" diskElapsed="+saved["elapsed"]);all=all && ok;
 }
 Test.assert(all);return true;
}
(:test)
function auditSessionRewardRetryDurableTest(logger){
 var all=true;
 for(var kind=0;kind<3;kind++){
  var s=ReliabilityAuditSupport.pet();var session=s.beginSession(kind);session["route"]=1;session["finds"]=1;s.saveSession(session);var before=s.store.copy(Storage.getValue("v4"));ReliabilityAuditSupport.failPet(s);var caught=false;
  try{s.completeSession(session,true);}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);Test.assert(s.store.same(before,Storage.getValue("v4")));
  ReliabilityAuditSupport.restorePet(s);var reply=s.completeSession(session,true);var saved=Storage.getValue("v4");
  var ok=saved["sessions"][kind]==null && saved["gameClaims"][kind]==session["id"];
  logger.debug("AUDIT reward kind="+kind+" reply="+reply+" durableClaim="+saved["gameClaims"][kind]+" liveClaim="+s.data["gameClaims"][kind]);all=all && ok;
 }
 Test.assert(all);return true;
}
(:test)
function auditBattleTurnCacheRetryDurableTest(logger){
 var s=ReliabilityAuditSupport.pet();var f=new BeastBattle(s);f.beginBattle();var before=s.store.copy(Storage.getValue("battle.v1"));
 var broken=new GenerationFailStore();s.store=broken;broken.failKey="battle.v1";var caught=false;
 try{f.battleTurn(1);}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);Test.assert(s.store.same(before,Storage.getValue("battle.v1")));
 broken.failKey=null;var next=new BeastBattle(s);next.postponeBattle();var saved=Storage.getValue("battle.v1");
 logger.debug("AUDIT turn live="+next.data["active"]["turn"]+" durable="+saved["active"]["turn"]);
 Test.assert(s.store.same(next.battleSession(),saved["active"]));return true;
}
class AuditHideTimer {
 var stopped=false;var stops=0;
 function initialize(){}
 function stop(){stopped=true;stops++;}
}
(:test)
function auditHiddenGameCheckpointFailureTest(logger){
 var all=true;var app=Toybox.Application.getApp();var prior=app.activeView;
 for(var kind=0;kind<3;kind++){
  var s=ReliabilityAuditSupport.pet();var game=new BeastGameView(s,kind);game.begin();game.elapsed=7;var timer=new AuditHideTimer();game.refresher=timer;app.activeView=game;
  ReliabilityAuditSupport.failPet(s);var caught=false;try{game.hideCore();}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);
  ReliabilityAuditSupport.restorePet(s);s.retrySession();s.storagePaused=false;app.onActive(null);
  var ok=timer.stopped && !game.gameHidden;logger.debug("AUDIT hide kind="+kind+" stopped="+timer.stopped+" hiddenAfterActive="+game.gameHidden);all=all && ok;
  // Dispose the audit sentinel without allowing a real callback to leak.
  game.refresher=null;game.gameHidden=false;game.onHide();app.activeView=null;
 }
 app.activeView=prior;Test.assert(all);return true;
}
(:test)
function auditOrdinaryCareRetryControlTest(logger){
 var s=ReliabilityAuditSupport.pet();ReliabilityAuditSupport.failPet(s);var caught=false;try{s.feedFood(true);}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);
 ReliabilityAuditSupport.restorePet(s);s.commit();Test.assert(s.store.same(Storage.getValue("v4"),s.data));var writes=s.store.writes;s.commit();Test.assertEqual(writes,s.store.writes);return true;
}

(:test)
function reliabilityRepeatedSessionRetryTest(logger){
 for(var kind=0;kind<3;kind++){
  for(var op=0;op<3;op++){
   var s=ReliabilityAuditSupport.pet();var session=null;
   if(op>0){session=s.beginSession(kind);session["round"]=2;session["elapsed"]=7;if(op==2){s.saveSession(session);}}
   var disk=s.store.copy(Storage.getValue("v4"));var pending=null;ReliabilityAuditSupport.failPet(s);
   for(var i=0;i<3;i++){
    var caught=false;try{if(op==0){s.beginSession(kind);}else if(op==1){s.saveSession(session);}else{s.completeSession(session,true);}}
    catch(e instanceof Toybox.Lang.Exception){caught=true;}
    Test.assert(caught);Test.assert(s.store.same(disk,Storage.getValue("v4")));
    if(i==0){pending=s.store.copy(s.data);}else{Test.assert(s.store.same(pending,s.data));}
   }
   ReliabilityAuditSupport.restorePet(s);
   if(op==0){session=s.beginSession(kind);}else if(op==1){Test.assert(s.saveSession(session));}else{s.completeSession(session,true);}
   Test.assert(s.store.same(s.data,Storage.getValue("v4")));var writes=s.store.writes;
   if(op==0){s.beginSession(kind);}else if(op==1){s.saveSession(session);}else{s.completeSession(session,true);}
   Test.assertEqual(writes,s.store.writes);
   var r=GenerationSupport.reload(s);Test.assert(s.store.same(s.data,r.data));
   Test.assertEqual(r.number("adventure"),kind==2?2:3);
   if(op==2){Test.assertEqual(r.data["gameClaims"][kind],session["id"]);Test.assert(r.data["sessions"][kind]==null);}
  }
 }
 return true;
}
class ReliabilityGame extends BeastGameView {
 var checkpoints=0;
 function initialize(s,k){BeastGameView.initialize(s,k);}
 function checkpoint(){checkpoints++;BeastGameView.checkpoint();}
}
(:test)
function reliabilityInactiveRepeatedFailureTest(logger){
 var app=Toybox.Application.getApp();var prior=app.activeView;
 for(var kind=0;kind<3;kind++){
  var s=ReliabilityAuditSupport.pet();var game=new ReliabilityGame(s,kind);game.begin();game.elapsed=7;
  var timer=new AuditHideTimer();game.refresher=timer;app.activeView=game;ReliabilityAuditSupport.failPet(s);
  var caught=false;try{game.hideCore();}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);
  var calls=game.checkpoints;app.onStop(null);Test.assertEqual(game.checkpoints,calls);Test.assertEqual(timer.stops,1);Test.assert(game.refresher==null);
  caught=false;try{game.showCore();}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);Test.assert(game.refresher==null);
  ReliabilityAuditSupport.restorePet(s);s.retrySession();s.storagePaused=false;app.onActive(null);Test.assert(!game.gameHidden);Test.assert(game.paused);
  Test.assertEqual(Storage.getValue("v4")["sessions"][kind]["elapsed"],7);Test.assertEqual(game.checkpoints,calls);
  game.resumeInput();Test.assertEqual(game.resumeTicks,3);Test.assert(game.refresher!=null);game.onHide();Test.assert(game.refresher==null);app.activeView=null;
  var r=GenerationSupport.reload(s);Test.assertEqual(r.data["sessions"][kind]["elapsed"],7);
 }
 app.activeView=prior;return true;
}
(:test)
function reliabilityCompletionControllerRecoveryTest(logger){
 for(var kind=0;kind<3;kind++){
  for(var fresh=0;fresh<2;fresh++){
   var s=ReliabilityAuditSupport.pet();var game=new BeastGameView(s,kind);game.begin();var session=s.store.copy(game.session);
   ReliabilityAuditSupport.failPet(s);var caught=false;try{s.completeSession(session,true);}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);
   var expected=s.store.copy(s.data);game.gameHidden=true;if(fresh==1){game=new BeastGameView(s,kind);}
   ReliabilityAuditSupport.restorePet(s);s.retrySession();game.onShow();Test.assert(game.session==null);Test.assertEqual(game.phase,0);Test.assert(!game.gameHidden);
   Test.assert(s.store.same(expected,Storage.getValue("v4")));var writes=s.store.writes;s.completeSession(session,true);Test.assertEqual(s.store.writes,writes);game.onHide();
   var r=GenerationSupport.reload(s);Test.assert(s.store.same(expected,r.data));
  }
 }
 return true;
}
(:test)
function reliabilityBattleTurnRepeatedRecoveryTest(logger){
 for(var fresh=0;fresh<2;fresh++){
  var s=ReliabilityAuditSupport.pet();var fight=new BeastBattle(s);fight.beginBattle();var durable=s.store.copy(Storage.getValue("battle.v1"));
  var broken=new GenerationFailStore();s.store=broken;broken.failKey="battle.v1";
  for(var attempt=0;attempt<3;attempt++){
   if(fresh==1){fight=new BeastBattle(s);}var caught=false;try{fight.battleTurn(1);}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);
   Test.assert(s.store.same(durable,s.battleData));Test.assert(s.store.same(durable,fight.data));Test.assert(s.store.same(durable,Storage.getValue("battle.v1")));
  }
  broken.failKey=null;fight.battleTurn(1);Test.assertEqual(fight.data["active"]["turn"],1);var saved=s.store.copy(Storage.getValue("battle.v1"));var writes=s.store.writes;
  fight=new BeastBattle(s);fight.postponeBattle();Test.assertEqual(s.store.writes,writes);Test.assert(s.store.same(saved,fight.data));
  var r=GenerationSupport.reload(s);var cold=new BeastBattle(r);Test.assert(r.store.same(saved,cold.data));Test.assertEqual(cold.data["active"]["turn"],1);
 }
 return true;
}
