using Toybox.Test;using Toybox.Application.Storage;using Toybox.System;
module SessionInterleaveSupport {
 function background(s,steps,elapsed){
  var b=new BeastStateCore();b.testNow=s.now()+elapsed;b.skipWatch=true;b.start();b.observe(b.today(),steps);b.tick();b.commit();return b;
 }
 function assertProgress(s,expected){
  var keys=["xp","days","counts","snacks","snackRemainder","activityBonus","baseGrowth","growthRemainder","lastGrowth","stageFloor","collection","charms","fullness","happiness","energy","cleanliness","lastCare","careAt","careStepDay","careStepUnits"];
  for(var i=0;i<keys.size();i++){Test.assert(s.store.same(expected[keys[i]],s.data[keys[i]]));}
 }
}
(:test)
function interleaveCheckpointRestartTest(logger){
 var all=true;
 for(var kind=0;kind<3;kind++){
  var s=ReliabilityAuditSupport.pet();var session=s.beginSession(kind);session["round"]=2;session["elapsed"]=7;s.store.failWrite=true;var caught=false;
  try{s.saveSession(session);}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);
  var bg=SessionInterleaveSupport.background(s,4000,3600);var expected=bg.store.copy(bg.data);s.store.failWrite=false;Test.assert(s.saveSession(session));
  // New VM-equivalent model: load only, no history reconciliation can repair it.
  var r=GenerationSupport.reload(s);var ok=r.xp()==expected["xp"];logger.debug("INTERLEAVE kind="+kind+" durableXP="+r.xp()+" expectedXP="+expected["xp"]);all=all && ok;
  Test.assertEqual(r.data["sessions"][kind]["elapsed"],7);
  if(ok){SessionInterleaveSupport.assertProgress(r,expected);}
 }
 Test.assert(all);return true;
}

(:test)
function interleaveRepeatedUpdatesTest(logger){
 for(var kind=0;kind<3;kind++){
  var s=ReliabilityAuditSupport.pet();var session=s.beginSession(kind);session["elapsed"]=9;session["round"]=2;s.store.failWrite=true;
  try{s.saveSession(session);}catch(e instanceof Toybox.Lang.Exception){}
  var expected=null;
  for(var i=1;i<=3;i++){
   var bg=SessionInterleaveSupport.background(s,i*4000,i*3600);bg.data["items"][7]=i;bg.data["friendship"]=30+i;bg.commit();expected=bg.store.copy(bg.data);
   var caught=false;try{s.saveSession(session);}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);
   Test.assert(s.store.same(expected,Storage.getValue("v4")));Test.assert(s.pendingSession!=null);Test.assert(!s.savingSession);
  }
  s.store.failWrite=false;Test.assert(s.saveSession(session));var r=GenerationSupport.reload(s);
  SessionInterleaveSupport.assertProgress(r,expected);Test.assertEqual(r.data["items"][7],3);Test.assertEqual(r.friendship(),33);Test.assertEqual(r.data["sessions"][kind]["elapsed"],9);
 }
 return true;
}
(:test)
function interleaveNoPendingBackgroundTest(logger){
 var s=ReliabilityAuditSupport.pet();var game=new BeastGameView(s,2);game.begin();var id=game.session["id"];
 var bg=SessionInterleaveSupport.background(s,6000,3600);var expected=bg.store.copy(bg.data);game.onShow();
 SessionInterleaveSupport.assertProgress(s,expected);Test.assertEqual(game.session["id"],id);Test.assertEqual(s.number("adventure"),2);game.onHide();return true;
}
(:test)
function interleaveCompletionRewardsTest(logger){
 for(var kind=0;kind<3;kind++){
  for(var capped=0;capped<2;capped++){
   var s=ReliabilityAuditSupport.pet();var session=s.beginSession(kind);session["route"]=1;session["finds"]=2;s.saveSession(session);s.store.failWrite=true;
   try{s.completeSession(session,true);}catch(e instanceof Toybox.Lang.Exception){}
   var bg=SessionInterleaveSupport.background(s,8000,3600);
   bg.data["items"][7]=4;bg.data["energy"]=60;bg.data["happiness"]=50;bg.data["friendship"]=40;bg.data["games"]=capped==0?1:3;bg.data["careToday"]=100;bg.commit();
   var expected=bg.store.copy(bg.data);s.store.failWrite=false;s.completeSession(session,true);var r=GenerationSupport.reload(s);
   Test.assertEqual(r.xp(),expected["xp"]);Test.assert(r.store.same(r.data["counts"],expected["counts"]));Test.assertEqual(r.number("baseGrowth"),expected["baseGrowth"]);Test.assertEqual(r.number("activityBonus"),expected["activityBonus"]);
   Test.assertEqual(r.data["gameClaims"][kind],session["id"]);Test.assert(r.data["sessions"][kind]==null);
   if(kind==2){
    var item=BeastGameRules.treasureItem(session["seed"],session["risk"],session["finds"],session["route"],expected["discoveryMask"]);
    for(var i=0;i<8;i++){Test.assertEqual(r.data["items"][i],expected["items"][i]+(i==item?1:0));}
    Test.assertEqual(r.number("games"),expected["games"]);Test.assertEqual(r.number("energy"),60);Test.assertEqual(r.friendship(),41);
   }else{
    Test.assert(r.store.same(r.data["items"],expected["items"]));Test.assertEqual(r.number("games"),capped==0?2:3);
    Test.assertEqual(r.number("energy"),capped==0?50:60);Test.assertEqual(r.friendship(),capped==0?42:40);
   }
   var reward=kind==2?25:(capped==0?75:0);
   Test.assertEqual(r.number("careGrowth"),expected["careGrowth"]+reward);Test.assertEqual(r.number("careToday"),expected["careToday"]+reward);
   Test.assertEqual(r.number("happiness"),kind==2 || capped==0?58:50);
   var family=kind==1?3:1;
   for(var a=0;a<4;a++){
    Test.assertEqual(r.data["affinity"][a],expected["affinity"][a]+(a==family?2:0));
    Test.assertEqual(r.data["affinityToday"][a],expected["affinityToday"][a]+(a==family?2:0));
    var change=kind==2?(a==1?2:0):(capped==0 && a==family?1:0);
    Test.assertEqual(r.data["personality"][a],expected["personality"][a]+change);
   }
   var untouched=["days","fullness","cleanliness","poop","poopSlots","digestion","careAt","lastCare","birthEpoch","petSerial","stageFloor","collection","rareCollection","charms","sound","haptics","sleepUntil","careDifficulty","careStepDay","careStepUnits"];
   for(var u=0;u<untouched.size();u++){Test.assert(r.store.same(r.data[untouched[u]],expected[untouched[u]]));}
   Test.assertEqual(r.number("adventure"),expected["adventure"]);var writes=s.store.writes;s.completeSession(session,true);Test.assertEqual(s.store.writes,writes);
  }
 }
 return true;
}
(:test)
function interleaveOwnershipConflictTest(logger){
 for(var mode=0;mode<3;mode++){
  var s=GenerationSupport.legendary(true);var session=s.beginSession(2);session["elapsed"]=9;s.store.failWrite=true;
  try{s.saveSession(session);}catch(e instanceof Toybox.Lang.Exception){}
  var other=GenerationSupport.reload(s);other.store=new BeastStore();
  if(mode==0){Test.assert(other.newEgg());}else if(mode==1){Test.assert(other.abandonSession(session));}else{other.completeSession(session,true);}
  var expected=other.store.copy(Storage.getValue("v4"));s.store.failWrite=false;Test.assert(!s.saveSession(session));
  Test.assert(s.store.same(expected,Storage.getValue("v4")));Test.assert(s.store.same(expected,s.data));Test.assert(s.pendingSession==null);
 }
 // A start saved by another controller resumes once, without a second debit.
 var s=ReliabilityAuditSupport.pet();s.store.failWrite=true;try{s.beginSession(2);}catch(e instanceof Toybox.Lang.Exception){}
 var other=GenerationSupport.reload(s);other.store=new BeastStore();var created=other.beginSession(2);var expected=other.store.copy(Storage.getValue("v4"));
 s.store.failWrite=false;Test.assertEqual(s.beginSession(2)["id"],created["id"]);Test.assert(s.store.same(expected,Storage.getValue("v4")));Test.assertEqual(s.number("adventure"),2);return true;
}
class InterleaveFailureStore extends PersistenceStore {
 var failRead=false;var afterWrite=false;
 function initialize(){PersistenceStore.initialize();}
 function read(key){if(failRead && key.equals("v4")){throw new Toybox.Lang.InvalidValueException("QA rebase read");}return PersistenceStore.read(key);}
 function write(key,value){var result=PersistenceStore.write(key,value);if(afterWrite && key.equals("v4")){afterWrite=false;throw new Toybox.Lang.InvalidValueException("QA post-write interruption");}return result;}
}
(:test)
function interleaveResolutionFailureTest(logger){
 var s=ReliabilityAuditSupport.pet();var session=s.beginSession(1);session["elapsed"]=11;s.store.failWrite=true;try{s.saveSession(session);}catch(e instanceof Toybox.Lang.Exception){}
 var bg=SessionInterleaveSupport.background(s,10000,3600);var expected=bg.store.copy(bg.data);var faults=new InterleaveFailureStore();s.store=faults;faults.failRead=true;
 var caught=false;try{s.saveSession(session);}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);Test.assert(s.pendingSession!=null);Test.assert(!s.savingSession);Test.assert(faults.same(expected,Storage.getValue("v4")));
 faults.failRead=false;faults.failWrite=true;caught=false;try{s.saveSession(session);}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);Test.assert(faults.same(expected,Storage.getValue("v4")));
 faults.failWrite=false;Test.assert(s.saveSession(session));var r=GenerationSupport.reload(s);SessionInterleaveSupport.assertProgress(r,expected);Test.assertEqual(r.data["sessions"][1]["elapsed"],11);return true;
}
(:test)
function interleavePostWriteAckTest(logger){
 for(var kind=0;kind<3;kind++){
  var s=ReliabilityAuditSupport.pet();var session=s.beginSession(kind);var faults=new InterleaveFailureStore();s.store=faults;faults.afterWrite=true;
  var caught=false;try{s.completeSession(session,true);}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);
  var bg=SessionInterleaveSupport.background(s,12000,3600);var expected=bg.store.copy(bg.data);
  s.completeSession(session,true);Test.assert(faults.same(expected,Storage.getValue("v4")));var r=GenerationSupport.reload(s);Test.assert(faults.same(expected,r.data));return true;
 }
}

class InterleaveMemoryStore extends PersistenceStore {
 var depth=0;var sampledPeak=0;var budget=0;
 function initialize(){PersistenceStore.initialize();}
 function sample(){var st=System.getSystemStats();sampledPeak=sampledPeak>st.usedMemory?sampledPeak:st.usedMemory;budget=st.totalMemory;}
 function copy(value){
  depth++;var result=null;
  try{result=PersistenceStore.copy(value);}catch(e instanceof Toybox.Lang.Exception){depth--;throw e;}
  depth--;if(depth==0){sample();}return result;
 }
 function write(key,value){sample();var result=PersistenceStore.write(key,value);sample();return result;}
}
class SessionMemoryRunner {
 var s=null;var meter=null;var game=null;var stage=0;var done=false;
 function initialize(){}
 function step(){
  if(stage==0){s=ReliabilityAuditSupport.pet();}
  else if(stage<=3){
   var kind=stage-1;var record=s.beginSession(kind);record["sequence"]=[0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0];record["hint"]="REPEAT THE SAME SEQUENCE";record["round"]=5;s.saveSession(record);
  }else if(stage==4){
   for(var i=0;i<32;i++){var day=s.dateKey(new Toybox.Time.Moment((s.now()-i*86400).toNumber()));s.data["days"][day%32]=day;s.data["counts"][day%32]=i==0?0:10000+i;}
   s.data["items"]=[100,100,100,100,100,100,100,100];s.commit();
  }else if(stage==5){
   meter=new InterleaveMemoryStore();s.store=meter;meter.canonical=meter.copy(s.data);
   game=meter.copy(s.data["sessions"][1]);game["elapsed"]=17;meter.failWrite=true;
   try{s.saveSession(game);}catch(e instanceof Toybox.Lang.Exception){}
  }else if(stage==6){SessionInterleaveSupport.background(s,16000,3600);}
  else{
   meter.failWrite=false;Test.assert(s.saveSession(game));
   var view=new BeastGameView(s,1);view.restore(game);var old=view.callbacks;view.bindCallbacks();old.refresh();meter.sample();
   Test.assert(view.callbacks!=old);
   System.println("SESSION_REBASE_MEMORY used="+meter.sampledPeak+" total="+meter.budget+" headroom="+(meter.budget-meter.sampledPeak)+" sessions=3");
   Test.assert(meter.sampledPeak<meter.budget);Test.assertEqual(s.xp(),16000l);done=true;
  }
  stage++;
 }
}
function sessionMemoryProbe(){var r=new SessionMemoryRunner();while(!r.done){r.step();}return true;}
(:test)
function interleaveMemoryShapeTest(logger){return sessionMemoryProbe();}
class SessionMemoryView extends Toybox.WatchUi.View {
 var runner;var timer=null;
 function initialize(){Toybox.WatchUi.View.initialize();runner=new SessionMemoryRunner();}
 function onShow(){timer=new Toybox.Timer.Timer();timer.start(method(:advance),100,true);}
 function onHide(){if(timer!=null){timer.stop();timer=null;}}
 function onUpdate(dc){}
 function advance(){runner.step();if(runner.done){onHide();System.println("SESSION_MEMORY_COMPLETE");System.exit();}}
}
(:background,:glance)
class SessionMemoryApp extends PersistenceApp {
 function initialize(){PersistenceApp.initialize();}
 function getInitialView(){return [new SessionMemoryView()];}
}

(:test)
function interleaveNewerCheckpointWinsTest(logger){
 for(var completing=0;completing<2;completing++){
  var s=ReliabilityAuditSupport.pet();var game=new BeastGameView(s,1);game.begin();game.elapsed=7;s.store.failWrite=true;
  if(completing==0){try{game.checkpoint();}catch(e instanceof Toybox.Lang.Exception){}}
  else{try{s.completeSession(game.session,true);}catch(e instanceof Toybox.Lang.Exception){}}
  var other=GenerationSupport.reload(s);other.store=new BeastStore();var newer=other.store.copy(other.data["sessions"][1]);newer["round"]=4;newer["elapsed"]=12;Test.assert(other.saveSession(newer));
  var expected=other.store.copy(Storage.getValue("v4"));s.store.failWrite=false;
  if(completing==0){game.elapsed=8;game.finish(true,game.callbacks);Test.assert(game.session==null);Test.assertEqual(game.phase,0);}
  else{Test.assert(s.completeSession(game.session,true).equals("SESSION CHANGED"));}
  Test.assert(s.store.same(expected,Storage.getValue("v4")));Test.assertEqual(s.number("games"),0);Test.assertEqual(s.data["gameClaims"][1],0);
 }
 return true;
}
(:test)
function interleaveLifecycleRetryTest(logger){
 for(var kind=0;kind<3;kind++){
  var s=ReliabilityAuditSupport.pet();var game=new BeastGameView(s,kind);game.begin();game.elapsed=13;s.store.failWrite=true;
  var caught=false;try{game.hideCore();}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);Test.assert(game.refresher==null);
  var bg=SessionInterleaveSupport.background(s,14000,3600);var expected=bg.store.copy(bg.data);s.store.failWrite=false;
  s.retrySession();if(kind==1){s.data=null;s.syncHistory();} // Same state boundary as onStorageChanged.
  game.onShow();Test.assert(!game.gameHidden);Test.assertEqual(game.elapsed,13);SessionInterleaveSupport.assertProgress(s,expected);
  var r=GenerationSupport.reload(s);SessionInterleaveSupport.assertProgress(r,expected);Test.assertEqual(r.data["sessions"][kind]["elapsed"],13);game.onHide();
 }
 return true;
}

// Invoke the actual production notification handler; the QA app otherwise
// suppresses unsolicited simulator storage callbacks to keep fixtures isolated.
class SessionNotificationHarness extends TekuTekuBeastApp {
 function initialize(view){activeView=view;}
}
(:test)
function interleaveStorageNotificationConflictTest(logger){
 for(var kind=0;kind<3;kind++){
  var s=ReliabilityAuditSupport.pet();var game=new BeastGameView(s,kind);game.begin();game.elapsed=7;s.store.failWrite=true;
  try{game.checkpoint();}catch(e instanceof Toybox.Lang.Exception){}
  var other=GenerationSupport.reload(s);other.store=new BeastStore();var newer=other.store.copy(other.data["sessions"][kind]);newer["elapsed"]=12;newer["round"]=4;other.saveSession(newer);
  other.observe(other.today(),4000);other.commit();s.store.failWrite=false;
  new SessionNotificationHarness(game).onStorageChanged();
  var expected=s.store.copy(Storage.getValue("v4"));
  var accepted=game.checkpoint();logger.debug("NOTIFICATION kind="+kind+" staleAccepted="+accepted+" durableElapsed="+Storage.getValue("v4")["sessions"][kind]["elapsed"]);
  Test.assert(!accepted);Test.assert(game.session==null);
  for(var i=0;i<3;i++){game.checkpoint();game.finish(true,game.callbacks);Test.assert(s.store.same(expected,Storage.getValue("v4")));}
  game.begin();Test.assertEqual(game.elapsed,12);Test.assertEqual(game.round,4);Test.assert(game.paused);game.onHide();
  var r=GenerationSupport.reload(s);Test.assertEqual(r.data["sessions"][kind]["elapsed"],12);Test.assertEqual(r.xp(),4000l);
 }
 return true;
}
(:test)
function interleaveNotificationRetirementTest(logger){
 for(var mode=0;mode<3;mode++){
  var s=GenerationSupport.legendary(true);var game=new BeastGameView(s,1);game.begin();game.elapsed=7;s.store.failWrite=true;
  try{game.checkpoint();}catch(e instanceof Toybox.Lang.Exception){}
  var other=GenerationSupport.reload(s);other.store=new BeastStore();
  if(mode==0){other.abandonSession(game.session);}else if(mode==1){other.completeSession(game.session,true);}else{other.newEgg();}
  s.store.failWrite=false;new SessionNotificationHarness(game).onStorageChanged();var expected=s.store.copy(Storage.getValue("v4"));
  for(var i=0;i<3;i++){game.checkpoint();game.finish(true,game.callbacks);Test.assert(s.store.same(expected,Storage.getValue("v4")));}
  Test.assert(game.session==null);var r=GenerationSupport.reload(s);Test.assert(s.store.same(expected,r.data));
 }
 return true;
}

(:test)
function interleaveNotificationCompletionTest(logger){
 for(var kind=0;kind<3;kind++){
  for(var callback=0;callback<2;callback++){
   var s=ReliabilityAuditSupport.pet();var game=new BeastGameView(s,kind);game.begin();game.elapsed=7;s.store.failWrite=true;
   try{game.checkpoint();}catch(e instanceof Toybox.Lang.Exception){}
   var other=GenerationSupport.reload(s);other.store=new BeastStore();var newer=other.store.copy(other.data["sessions"][kind]);newer["elapsed"]=12;other.saveSession(newer);
   s.store.failWrite=false;new SessionNotificationHarness(game).onStorageChanged();var expected=s.store.copy(Storage.getValue("v4"));
   // No prior checkpoint may be needed to consume the controller invalidation.
   if(callback==0){game.finish(true,game.callbacks);}else{game.restartGame();}
   Test.assert(game.session==null);Test.assert(s.store.same(expected,Storage.getValue("v4")));
   for(var i=0;i<3;i++){game.finish(true,game.callbacks);game.checkpoint();Test.assert(s.store.same(expected,Storage.getValue("v4")));}
   game.retryRecovery();Test.assert(game.paused);Test.assertEqual(game.elapsed,12);game.onHide();
  }
 }
 return true;
}

module SessionOwnershipSupport {
 function completion(game){return (game has :callbacks)?game.callbacks.method(:finish):game.method(:finish);}
}
(:test)
function sessionStaleRestoreOwnershipTest(logger){
 for(var kind=0;kind<3;kind++){
  var s=ReliabilityAuditSupport.pet();var game=new BeastGameView(s,kind);game.begin();var old=s.store.copy(game.session);
  var other=GenerationSupport.reload(s);other.store=new BeastStore();var newer=other.store.copy(other.data["sessions"][kind]);newer["elapsed"]=12;newer["round"]=2;other.saveSession(newer);other.observe(other.today(),4000);other.commit();
  game.restore(old);Test.assertEqual(game.elapsed,12);game.elapsed++;game.checkpoint();var r=GenerationSupport.reload(s);
  logger.debug("RESTORE kind="+kind+" durableElapsed="+r.data["sessions"][kind]["elapsed"]);
  Test.assertEqual(r.data["sessions"][kind]["elapsed"],13);Test.assertEqual(r.xp(),4000l);
 }
 return true;
}
(:test)
function sessionDelayedCompletionOwnershipTest(logger){
 for(var kind=0;kind<3;kind++){
  var s=ReliabilityAuditSupport.pet();var game=new BeastGameView(s,kind);game.begin();var old=SessionOwnershipSupport.completion(game);
  game.restore(s.store.copy(game.session));var expected=s.store.copy(Storage.getValue("v4"));
  old.invoke(true);logger.debug("OLD_COMPLETION kind="+kind+" claim="+Storage.getValue("v4")["gameClaims"][kind]);
  Test.assert(s.store.same(expected,Storage.getValue("v4")));
 }
 return true;
}

(:test)
function sessionCallbackRefreshChainTest(logger){
 for(var kind=0;kind<3;kind++){
  var s=ReliabilityAuditSupport.pet();var game=new BeastGameView(s,kind);game.begin();var old=[];var ticks=[];
  for(var n=0;n<3;n++){
   old.add(SessionOwnershipSupport.completion(game));ticks.add(game.callbacks.method(:refresh));
   game.restore(s.store.copy(game.session));var expected=s.store.copy(Storage.getValue("v4"));var elapsed=game.elapsed;
   for(var i=0;i<old.size();i++){old[i].invoke(true);ticks[i].invoke();Test.assert(s.store.same(expected,Storage.getValue("v4")));Test.assertEqual(game.elapsed,elapsed);}
  }
  var id=game.session["id"];var current=SessionOwnershipSupport.completion(game);current.invoke(true);
  var expected=s.store.copy(Storage.getValue("v4"));Test.assertEqual(expected["gameClaims"][kind],id);Test.assert(expected["sessions"][kind]==null);
  var writes=s.store.writes;current.invoke(true);for(var i=0;i<old.size();i++){old[i].invoke(true);ticks[i].invoke();}
  Test.assertEqual(s.store.writes,writes);var r=GenerationSupport.reload(s);Test.assert(s.store.same(expected,r.data));Test.assertEqual(r.number("adventure"),kind==2?2:3);
 }
 return true;
}
(:test)
function sessionCallbackReconstructionTest(logger){
 for(var kind=0;kind<3;kind++){
  var s=ReliabilityAuditSupport.pet();var game=new BeastGameView(s,kind);game.begin();var old=SessionOwnershipSupport.completion(game);var timer=game.callbacks.method(:refresh);game.elapsed=9;s.store.failWrite=true;
  try{game.checkpoint();}catch(e instanceof Toybox.Lang.Exception){}
  SessionInterleaveSupport.background(s,4000,3600);s.store.failWrite=false;
  s.retrySession();var fresh=new BeastGameView(s,kind);fresh.onShow();var expected=s.store.copy(Storage.getValue("v4"));Test.assertEqual(fresh.elapsed,9);
  for(var i=0;i<3;i++){old.invoke(true);timer.invoke();Test.assert(s.store.same(expected,Storage.getValue("v4")));}
  Test.assert(game.session==null);var writes=s.store.writes;game.checkpoint();Test.assertEqual(s.store.writes,writes);fresh.onHide();var r=GenerationSupport.reload(s);Test.assertEqual(r.data["sessions"][kind]["elapsed"],9);Test.assertEqual(r.xp(),4000l);Test.assertEqual(r.number("adventure"),kind==2?2:3);
 }
 return true;
}
(:test)
function sessionCallbackRetirementTest(logger){
 for(var mode=0;mode<3;mode++){
  var s=GenerationSupport.legendary(true);var game=new BeastGameView(s,1);game.begin();var snapshot=s.store.copy(game.session);var old=SessionOwnershipSupport.completion(game);
  var other=GenerationSupport.reload(s);other.store=new BeastStore();
  if(mode==0){other.newEgg();}else if(mode==1){other.abandonSession(snapshot);other.beginSession(1);}else{other.completeSession(snapshot,true);}
  new SessionNotificationHarness(game).onStorageChanged();var expected=s.store.copy(Storage.getValue("v4"));
  old.invoke(true);Test.assert(s.store.same(expected,Storage.getValue("v4")));
  game.restore(snapshot);expected=s.store.copy(Storage.getValue("v4"));for(var i=0;i<3;i++){old.invoke(true);Test.assert(s.store.same(expected,Storage.getValue("v4")));}
  if(mode==1){Test.assert(game.session["id"]!=snapshot["id"]);}else{Test.assert(game.session==null);}
  var r=GenerationSupport.reload(s);Test.assert(s.store.same(expected,r.data));
 }
 return true;
}

class SessionBindingTimer {
 var callback=null;var starts=0;var stops=0;
 function initialize(){}
 function start(next,period,repeating){callback=next;starts++;}
 function stop(){stops++;}
}
(:test)
function sessionTimerBindingHandoffTest(logger){
 for(var kind=0;kind<3;kind++){
  var s=ReliabilityAuditSupport.pet();var game=new BeastGameView(s,kind);game.begin();var timer=new SessionBindingTimer();game.refresher=timer;game.timerPeriod=250;game.bindCallbacks();
  var old=timer.callback;var completion=SessionOwnershipSupport.completion(game);game.restore(s.store.copy(game.session));
  Test.assert(timer.starts>=2);var current=timer.callback;var before=game.elapsed;var travel=game.travel;
  old.invoke();completion.invoke(true);Test.assertEqual(game.elapsed,before);Test.assertEqual(game.travel,travel);Test.assertEqual(s.data["gameClaims"][kind],0);
  current.invoke();Test.assert(game.elapsed>before || game.travel>travel);game.onHide();Test.assert(game.refresher==null);Test.assert(timer.stops>0);
 }
 return true;
}
