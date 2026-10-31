using Toybox.Test;

(:test)
module FriendModelTestSupport {
    function pet(){
        var s=TestSupport.fixture();s.data["stageFloor"]=2;s.data["sleepMode"]=2;s.data["snacks"]=17;
        s.data["friendship"]=73;s.data["personality"]=[1,4,2,3];s.commit();
        var solo=new BeastBattle(s);solo.beginBattle();solo.battleTurn(1);
        solo.data["xp"]=240;solo.data["mastery"][0]=27;solo.commit();s.commit();return s;
    }
    function unchanged(s,pet,journal,cache,writes){
        Test.assert(TestSupport.same(s.store.read("v4"),pet));
        Test.assert(TestSupport.same(s.store.read("battle.v1"),journal));
        Test.assert(TestSupport.same(s.battleData,cache));Test.assertEqual(s.store.writes,writes);
    }
}
(:test)
function friendModelSnapshotReadOnlyAndDetachedTest(logger){
    var s=FriendModelTestSupport.pet();var pet=s.store.copy(s.store.read("v4"));
    var journal=s.store.copy(s.store.read("battle.v1"));var cache=s.store.copy(s.battleData);var live=s.store.copy(s.data);var writes=s.store.writes;
    var actor=BeastFriendModel.snapshot(s);Test.assertEqual(actor["form"],1);Test.assertEqual(actor["friendship"],73);
    actor["hp"]=1;actor["mastery"][0]=999;
    FriendModelTestSupport.unchanged(s,pet,journal,cache,writes);Test.assert(TestSupport.same(s.data,live));
    s.battleData=null;var restored=BeastFriendModel.snapshot(s);Test.assertEqual(restored["hp"],restored["maxHp"]);
    Test.assert(s.battleData==null);FriendModelTestSupport.unchanged(s,pet,journal,null,writes);
    // Missing journal is read-only too: no constructor/discovery creates it.
    var fresh=TestSupport.fixture();fresh.data["stageFloor"]=3;fresh.data["family"]=0;var original=fresh.store.copy(fresh.data);var count=fresh.store.writes;
    var unlocked=BeastFriendModel.snapshot(fresh);Test.assert(unlocked["family"]>0);
    Test.assert(TestSupport.same(original,fresh.data));Test.assertEqual(fresh.store.writes,count);
    Test.assert(fresh.store.read("battle.v1")==null);return true;
}
(:test)
function friendModelFullMatchAndSerialIsolationTest(logger){
    var s=FriendModelTestSupport.pet();var pet=s.store.copy(s.store.read("v4"));
    var journal=s.store.copy(s.store.read("battle.v1"));var cache=s.store.copy(s.battleData);var writes=s.store.writes;
    Test.assertEqual(BeastFriendModel.serial(s),1);Test.assertEqual(s.store.writes,writes+1);
    var pair=new FriendLinkTestPair(BeastFriendModel.snapshot(s),FriendWireTestSupport.actor(0,0,0,0));pair.connect();
    for(var i=0;i<20 && pair.host.phase.equals("PLAY");i++){
        pair.turn(BeastBattleRules.availableAt(pair.host.battle,0,3)?3:0,0);
    }
    Test.assertEqual(pair.host.phase,"RESULT");Test.assertEqual(pair.join.phase,"RESULT");
    FriendModelTestSupport.unchanged(s,pet,journal,cache,writes+1);Test.assertEqual(s.store.read("friend.serial.v1"),1);
    var cancelled=new FriendLinkTestPair(BeastFriendModel.snapshot(s),BeastFriendModel.snapshot(s));cancelled.connect();
    cancelled.host.cancel(cancelled.now);Test.assert(cancelled.until("CLOSED","CLOSED",60));
    FriendModelTestSupport.unchanged(s,pet,journal,cache,writes+1);
    Test.assertEqual(BeastFriendModel.serial(s),2);Test.assertEqual(s.store.writes,writes+2);
    s.store.memory["friend.serial.v1"]=16777215;var before=s.store.writes;
    Test.assertEqual(BeastFriendModel.serial(s),0);Test.assertEqual(s.store.writes,before);return true;
}
(:test)
function friendViewConstructorLifecycleAndDevSnapshotTest(logger){
    var s=FriendModelTestSupport.pet();var pet=s.store.copy(s.store.read("v4"));
    var journal=s.store.copy(s.store.read("battle.v1"));var cache=s.store.copy(s.battleData);var writes=s.store.writes;
    var view=new BeastFriendView(s);Test.assert(view.fight==null);Test.assert(view.link==null);Test.assert(!view.radio.opened);
    view.onHide();Test.assert(view.battleTimer==null);Test.assert(!view.radio.opened);
    FriendModelTestSupport.unchanged(s,pet,journal,cache,writes);
    var dev=new TekuTekuBeastState();dev.store=s.store;dev.data=s.store.copy(s.data);dev.dev=true;dev.skipWatch=true;
    dev.testNow=s.testNow;dev.virtualNow=s.realNow();dev.anchor=s.realNow();dev.data["forcedStage"]=5;dev.data["forcedFamily"]=2;
    var actor=BeastFriendModel.snapshot(dev);Test.assertEqual(actor["family"],2);Test.assertEqual(actor["stage"],5);
    actor["mastery"][0]=999;actor["hp"]=0;
    FriendModelTestSupport.unchanged(s,pet,journal,cache,writes);
    view.role=1;var battle=BeastBattleRules.create(1,123,FriendWireTestSupport.actor(0,0,0,0),FriendWireTestSupport.actor(16,12,2,100));
    battle["actors"][0]["hp"]=1;battle=BeastBattleRules.pairedTurn(battle,0,3);var original=s.store.copy(battle);var shown=view.displayState(battle);
    Test.assertEqual(shown["actors"][0]["form"],16);Test.assertEqual(shown["actors"][1]["form"],0);
    Test.assertEqual(shown["events"][0]["actor"],1);Test.assertEqual(shown["status"],1);
    Test.assert(TestSupport.same(battle,original));return true;
}
