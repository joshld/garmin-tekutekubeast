using Toybox.Test;using Toybox.Application.Storage;
module GenerationSupport {
 function legendary(disk){if(disk){Storage.deleteValue("battle.v1");Storage.deleteValue("v4.archive");}var s=PersistenceSupport.fixture(disk);s.data["birthEpoch"]=s.now()-30*86400;s.data["stageFloor"]=5;s.data["baseGrowth"]=300000l;s.data["family"]=1;s.data["adventure"]=3;s.data["items"][5]=2;s.data["collection"]=15;s.data["rareCollection"]=3;s.commit();return s;}
 function reload(s){var r=new PersistencePet();r.clock=s.now();r.store=s.store;r.start();return r;}
}
(:test)
function generationSessionsRetiredTest(logger){
 var s=GenerationSupport.legendary(true);var old=[];
 for(var k=0;k<3;k++){var g=s.beginSession(k);g["round"]=2;g["sequence"]=[0,0,1];s.saveSession(g);old.add(g);}
 var serial=s.number("gameSerial");var energy=s.number("adventure");var xp=s.xp();var friend=s.friendship();
 Test.assert(s.newEgg());var r=GenerationSupport.reload(s);
 for(var k=0;k<3;k++){Test.assert(r.data["sessions"][k]==null);Test.assert(!r.saveSession(old[k]));Test.assert(!r.abandonSession(old[k]));Test.assert(r.completeSession(old[k],true).equals("ALREADY SAVED"));}
 Test.assertEqual(r.number("adventure"),energy);Test.assertEqual(r.xp(),xp);Test.assertEqual(r.friendship(),friend);Test.assertEqual(r.number("games"),0);
 Test.assertEqual(r.number("gameSerial"),serial);Test.assertEqual(r.data["items"][5],2);
 var fresh=r.beginSession(1);Test.assert(fresh["id"]>serial);Test.assert(!r.saveSession(old[1]));return true;
}
(:test)
function generationWildRetiredTest(logger){
 var s=GenerationSupport.legendary(true);var f=new BeastBattle(s);f.data["xp"]=50;f.data["mastery"][0]=4;f.beginBattle();f.battleTurn(1);var old=f.battleSession();var queue=s.store.copy(f.data["queue"]);var cap=f.data["rewarded"];f.commit();
 Test.assert(s.newEgg());var r=GenerationSupport.reload(s);var next=new BeastBattle(r);
 Test.assert(!next.hasUnfinishedBattle());Test.assert(next.battleSession()==null);Test.assert(s.store.same(queue,next.data["queue"]));Test.assertEqual(next.battleXp(),50);Test.assertEqual(next.data["mastery"][0],4);Test.assertEqual(next.data["rewarded"],cap);
 Test.assert(f.battleTurn(0)==null);Test.assert(!f.abandonBattle(old["id"]));f.postponeBattle();
 r.battleData=null;var again=new BeastBattle(r);Test.assert(again.battleSession()==null);Test.assertEqual(again.battleXp(),50);return true;
}

(:test)
function generationEarnedResultTest(logger){
 var s=GenerationSupport.legendary(true);var f=new BeastBattle(s);f.beginBattle();f.data["active"]["actors"][1]["hp"]=1;f.battleTurn(0);Test.assertEqual(f.data["active"]["status"],1);
 var expected=BeastBattleRules.xpReward(f.data["active"]);s.data["sleepUntil"]=s.now()+3600;s.commit();Test.assert(s.isSleeping());
 Test.assert(s.newEgg());var r=GenerationSupport.reload(s);var b=new BeastBattle(r);Test.assertEqual(b.battleXp(),expected);Test.assertEqual(b.data["rewarded"],1);Test.assertEqual(b.data["wins"],1);Test.assert(b.battleSession()==null);
 b.claimFinishedBattle();r.battleData=null;b=new BeastBattle(r);Test.assertEqual(b.battleXp(),expected);Test.assertEqual(b.data["rewarded"],1);return true;
}
(:test)
function generationLegacyAndSamePetResumeTest(logger){
 var s=GenerationSupport.legendary(true);var game=s.beginSession(1);game["sequence"]=[1,1,2];game["round"]=3;s.saveSession(game);
 var f=new BeastBattle(s);f.beginBattle();f.battleTurn(1);var match=f.battleSession();f.data.remove("petSerial");f.commit();s.battleData=null;
 var r=GenerationSupport.reload(s);var b=new BeastBattle(r);Test.assert(b.hasUnfinishedBattle());Test.assert(r.store.same(match,b.battleSession()));Test.assert(r.store.same(game,r.beginSession(1)));Test.assertEqual(b.data["petSerial"],r.number("petSerial"));
 Test.assertEqual(r.number("version"),4);var writes=r.store.writes;b=new BeastBattle(r);Test.assertEqual(r.store.writes,writes);return true;
}
(:test)
function generationCarryForwardTest(logger){
 var s=GenerationSupport.legendary(true);s.observe(s.today(),14000);s.data["games"]=2;s.data["careToday"]=200;s.data["rested"]=1;s.data["pats"]=2;s.data["gameClaims"]=[8,9,10];s.data["gameSerial"]=10;
 s.data["poop"]=2;s.data["poopSlots"]=5;s.data["digestion"]=[s.now()+7200,3,0l,0,0l,0,0l,0];s.commit();
 var before=s.store.copy(s.data);Test.assert(s.newEgg());var r=GenerationSupport.reload(s);
 var keep=["xp","snacks","snackRemainder","days","counts","birthBaseline","friendship","items","equipped","collection","rareCollection","charms","encounters","adventure","day","games","gameSerial","gameClaims","careToday","rested","patDay","pats","activityMilestone","minutesBase","pushBase","fullness","happiness","energy","cleanliness","poop","poopSlots","digestion","careDifficulty","sleepMode","sound","haptics","motion"];
 for(var i=0;i<keep.size();i++){Test.assert(r.store.same(before[keep[i]],r.data[keep[i]]));}
 Test.assertEqual(r.number("petSerial"),before["petSerial"]+1);Test.assertEqual(r.stage(),0);Test.assertEqual(r.growth(),0l);Test.assertEqual(r.number("family"),0);Test.assertEqual(r.number("rare"),0);
 Test.assert(r.store.same(before,r.store.read("v4.archive")));Test.assert(r.store.same(r.data["personality"],[0,0,0,0]));Test.assert(r.store.same(r.data["affinity"],[0,0,0,0]));return true;
}
class GenerationFailStore extends PersistenceStore {
 var failKey=null;
 function initialize(){PersistenceStore.initialize();}
 function write(key,value){if(failKey!=null && key.equals(failKey)){throw new Toybox.Lang.InvalidValueException("QA generation boundary");}return PersistenceStore.write(key,value);}
}
(:test)
function generationFailureRecoveryTest(logger){
 var failures=["battle.v1","v4.archive","v4"];
 for(var i=0;i<failures.size();i++){
  var s=GenerationSupport.legendary(true);var f=new BeastBattle(s);f.beginBattle();f.data["active"]["actors"][1]["hp"]=1;f.battleTurn(0);Test.assertEqual(f.data["active"]["status"],1);var xp=BeastBattleRules.xpReward(f.data["active"]);var serial=s.number("petSerial");
  var broken=new GenerationFailStore();s.store=broken;broken.failKey=failures[i];var failed=false;try{s.newEgg();}catch(e instanceof Toybox.Lang.Exception){failed=true;}Test.assert(failed);broken.failKey=null;
  var r=GenerationSupport.reload(s);Test.assertEqual(r.number("petSerial"),serial);Test.assertEqual(r.stage(),5);Test.assert(r.newEgg());r=GenerationSupport.reload(r);var battle=new BeastBattle(r);
  Test.assertEqual(r.number("petSerial"),serial+1);Test.assertEqual(battle.battleXp(),xp);Test.assertEqual(battle.data["rewarded"],1);Test.assert(battle.battleSession()==null);Test.assert(!r.newEgg());
 }return true;
}
(:test)
function generationDeveloperIsolationTest(logger){
 var s=GenerationSupport.legendary(true);s.beginSession(2);var f=new BeastBattle(s);f.beginBattle();var pet=s.store.copy(s.store.read("v4"));var fight=s.store.copy(s.store.read("battle.v1"));var archive=s.store.read("v4.archive");
 var d=s.enableDev();Test.assert(d.newEgg());var b=new BeastBattle(d);Test.assert(b.battleSession()==null);Test.assert(d.data["sessions"][2]==null);
 Test.assert(s.store.same(pet,s.store.read("v4")));Test.assert(s.store.same(fight,s.store.read("battle.v1")));Test.assert(s.store.same(archive,s.store.read("v4.archive")));Test.assert(f.hasUnfinishedBattle());return true;
}

module GenerationClaimSupport {
 function won(){
  var s=GenerationSupport.legendary(true);var f=new BeastBattle(s);f.beginBattle();f.data["active"]["actors"][1]["hp"]=1;f.battleTurn(0);Test.assertEqual(f.data["active"]["status"],1);
  var broken=new GenerationFailStore();s.store=broken;return [s,f,broken];
 }
 function expected(s,f){
  var match=f.data["active"];var mastery=s.store.copy(f.data["mastery"]);var increments=BeastBattleRules.masteryReward(match);
  for(var i=0;i<72;i++){mastery[i]=s.min(BeastBattleData.MASTERY_CAP,mastery[i]+increments[i]);}
  return [f.battleXp()+BeastBattleRules.xpReward(match),mastery,match["id"],f.data["rewarded"]+1,f.data["wins"]+1];
 }
 function assertClaim(s,expected){
  var saved=s.store.read("battle.v1");Test.assertEqual(saved["xp"],expected[0]);Test.assert(s.store.same(saved["mastery"],expected[1]));
  Test.assertEqual(saved["claim"],expected[2]);Test.assertEqual(saved["rewarded"],expected[3]);Test.assertEqual(saved["wins"],expected[4]);
 }
}
(:test)
function generationClaimSameProcessRetryTest(logger){
 for(var mode=0;mode<3;mode++){
  var parts=GenerationClaimSupport.won();var s=parts[0];var f=parts[1];var broken=parts[2];var expected=GenerationClaimSupport.expected(s,f);
  var durable=s.store.copy(s.store.read("battle.v1"));var serial=s.number("petSerial");broken.failKey="battle.v1";
  for(var attempt=0;attempt<3;attempt++){
   var caught=false;
   try{if(mode==0){f.finishBattle();}else if(mode==1){new BeastBattle(s).finishBattle();}else{s.newEgg();}}
   catch(e instanceof Toybox.Lang.Exception){caught=true;}
   Test.assert(caught);Test.assert(s.store.same(durable,s.store.read("battle.v1")));Test.assert(s.store.same(durable,s.battleData));
   Test.assert(!f.data["active"]["claimed"]);Test.assertEqual(s.number("petSerial"),serial);
  }
  broken.failKey=null;
  if(mode==1){var fresh=new BeastBattle(s);fresh.finishBattle();GenerationClaimSupport.assertClaim(s,expected);var writes=s.store.writes;f.finishBattle();fresh.finishBattle();Test.assertEqual(s.store.writes,writes);}
  Test.assert(s.newEgg());GenerationClaimSupport.assertClaim(s,expected);
  var r=GenerationSupport.reload(s);var b=new BeastBattle(r);GenerationClaimSupport.assertClaim(r,expected);Test.assert(b.battleSession()==null);
  var writes=r.store.writes;b.claimFinishedBattle();f.claimFinishedBattle();Test.assertEqual(r.store.writes,writes);
 }
 return true;
}
(:test)
function generationClaimDurableRecoveryTest(logger){
 var parts=GenerationClaimSupport.won();var s=parts[0];var f=parts[1];var broken=parts[2];var expected=GenerationClaimSupport.expected(s,f);
 var durable=s.store.copy(s.store.read("battle.v1"));broken.failKey="battle.v1";var caught=false;try{f.finishBattle();}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);
 broken.failKey=null;var r=GenerationSupport.reload(s);var b=new BeastBattle(r);Test.assert(r.store.same(durable,b.data));b.finishBattle();GenerationClaimSupport.assertClaim(r,expected);
 var writes=r.store.writes;b.finishBattle();Test.assertEqual(r.store.writes,writes);return true;
}
(:test)
function generationRetirementInterruptedRetryTest(logger){
 var parts=GenerationClaimSupport.won();var s=parts[0];var f=parts[1];var broken=parts[2];var expected=GenerationClaimSupport.expected(s,f);
 Test.assert(s.newEgg());GenerationClaimSupport.assertClaim(s,expected);var durable=s.store.copy(s.store.read("battle.v1"));broken.failKey="battle.v1";
 for(var attempt=0;attempt<2;attempt++){
  var caught=false;try{new BeastBattle(s);}catch(e instanceof Toybox.Lang.Exception){caught=true;}Test.assert(caught);
  Test.assert(s.store.same(durable,s.store.read("battle.v1")));f.postponeBattle();Test.assert(s.store.same(durable,s.store.read("battle.v1")));
 }
 broken.failKey=null;var current=new BeastBattle(s);Test.assert(current.battleSession()==null);Test.assertEqual(current.data["petSerial"],s.number("petSerial"));GenerationClaimSupport.assertClaim(s,expected);
 var r=GenerationSupport.reload(s);var again=new BeastBattle(r);GenerationClaimSupport.assertClaim(r,expected);Test.assert(again.battleSession()==null);return true;
}
