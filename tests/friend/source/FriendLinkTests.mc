using Toybox.Test;

// Two deterministic radios: one master broadcast and one slave reply per 250ms.
// This exercises the real protocol, not Garmin ANT hardware connectivity.
(:test)
class FriendLinkTestPair {
    var host;var join;var now=0;var packets=0;var dropEvery=0;var duplicate=false;
    function initialize(first,second){
        host=new BeastFriendLink(true,456789,0,first,now);
        join=new BeastFriendLink(false,0,32123,second,now);
    }
    function send(from,to){
        var packet=from.next(now);packets++;
        if(packet!=null && (dropEvery==0 || packets%dropEvery!=0)){
            to.receive(packet,now);if(duplicate){to.receive(packet,now);}
        }
    }
    function tick(){now+=250;send(host,join);send(join,host);}
    function until(first,second,limit){
        for(var i=0;i<limit;i++){
            if(host.phase.equals(first) && join.phase.equals(second)){return true;}tick();
        }
        return host.phase.equals(first) && join.phase.equals(second);
    }
    function connect(){
        var connected=until("READY","READY",200);if(!connected){Toybox.System.println("FRIEND_DIAG host="+host.phase+" / "+host.reason+" rx="+host.rx+" tx="+host.tx+" join="+join.phase+" / "+join.reason+" rx="+join.rx+" tx="+join.tx);}
        Test.assert(connected);
        Test.assert(TestSupport.same(host.localActor,join.remoteActor));
        Test.assert(TestSupport.same(join.localActor,host.remoteActor));
        Test.assert(host.ready(now));Test.assert(join.ready(now));
        Test.assert(!host.ready(now));Test.assert(!join.ready(now));
        Test.assert(until("PLAY","PLAY",80));
        Test.assert(TestSupport.same(host.battle,join.battle));
    }
    function turn(first,second){
        var before=host.battle["turn"];
        Test.assert(host.choose(first,now));Test.assert(join.choose(second,now));
        Test.assert(!host.choose(first,now));Test.assert(!join.choose(second,now));
        Test.assert(until("PRESENT","PRESENT",200));
        Test.assertEqual(host.battle["turn"],before+1);
        Test.assert(TestSupport.same(host.battle,join.battle));
        // Both screens complete their bounded presentation before next choices.
        if(host.battle["status"]!=0){
            for(var i=0;i<60 && (!host.finalConfirmed || !join.finalConfirmed);i++){tick();}
            Test.assert(host.finalConfirmed);Test.assert(join.finalConfirmed);
        }
        host.presentationDone(now);join.presentationDone(now);
    }
}
(:test)
function friendLinkHandshakeAndSnapshotIsolationTest(logger){
    var first=FriendWireTestSupport.actor(1,4,0,70);var second=FriendWireTestSupport.actor(5,2,3,30);
    var before=BeastFriendWire.actorBytes(first);var pair=new FriendLinkTestPair(first,second);pair.connect();
    Test.assertEqual(pair.host.sid,pair.join.sid);Test.assertEqual(pair.host.token,32123);
    Test.assertEqual(pair.host.battle["actors"][0]["form"],1);Test.assertEqual(pair.join.battle["actors"][1]["form"],5);
    pair.turn(2,1);pair.turn(3,0);
    Test.assert(TestSupport.same(BeastFriendWire.actorBytes(first),before));
    Test.assertEqual(second["hp"],second["maxHp"]);return true;
}
(:test)
function friendLinkLossDuplicatesAndStalePacketsTest(logger){
    var pair=new FriendLinkTestPair(FriendWireTestSupport.actor(6,3,0,50),FriendWireTestSupport.actor(10,3,1,50));
    pair.dropEvery=5;pair.duplicate=true;pair.connect();
    var rx=pair.host.rx;var revision=pair.host.changed;
    pair.host.receive(BeastFriendWire.frame(pair.host.sid+1,rx,12,0,0),pair.now);
    pair.host.receive(BeastFriendWire.frame(pair.host.sid,rx+1,12,0,0),pair.now);
    pair.host.receive(BeastFriendWire.frame(pair.host.sid,rx,12,9,0),pair.now);
    pair.host.receive([0,0,0],pair.now);
    Test.assertEqual(pair.host.rx,rx);Test.assertEqual(pair.host.changed,revision);
    pair.turn(1,2);pair.turn(0,3);
    Test.assertEqual(pair.host.battle["turn"],2);
    Test.assert(TestSupport.same(pair.host.battle,pair.join.battle));return true;
}
(:test)
function friendLinkCompleteWinLossAndDrawTest(logger){
    for(var winningSide=0;winningSide<2;winningSide++){
        var strong=FriendWireTestSupport.actor(16,12,2,100);var weak=FriendWireTestSupport.actor(0,0,0,0);
        var pair=new FriendLinkTestPair(winningSide==0?strong:weak,winningSide==0?weak:strong);pair.connect();
        for(var turn=0;turn<20 && pair.host.phase.equals("PLAY");turn++){
            var hostMove=BeastBattleRules.availableAt(pair.host.battle,0,3)?3:0;
            var joinMove=BeastBattleRules.availableAt(pair.join.battle,1,3)?3:0;
            pair.turn(hostMove,joinMove);
        }
        Test.assertEqual(pair.host.phase,"RESULT");Test.assertEqual(pair.join.phase,"RESULT");
        Test.assertEqual(pair.host.battle["status"],winningSide+1);
        Test.assert(TestSupport.same(pair.host.battle,pair.join.battle));
    }
    var pair=new FriendLinkTestPair(FriendWireTestSupport.actor(1,0,0,0),FriendWireTestSupport.actor(1,0,0,0));pair.connect();
    for(var turn=0;turn<20;turn++){pair.turn(1,1);}
    Test.assertEqual(pair.host.battle["status"],3);Test.assertEqual(pair.host.battle["turn"],20);
    Test.assertEqual(pair.host.phase,"RESULT");Test.assertEqual(pair.join.phase,"RESULT");return true;
}
(:test)
function friendLinkCancelTimeoutAndClockTest(logger){
    var first=FriendWireTestSupport.actor(0,0,0,0);
    for(var cancellingSide=0;cancellingSide<2;cancellingSide++){
        var pair=new FriendLinkTestPair(first,first);pair.connect();
        var leaving=cancellingSide==0?pair.host:pair.join;leaving.cancel(pair.now);leaving.cancel(pair.now);
        Test.assert(pair.until("CLOSED","CLOSED",60));Test.assert(!pair.host.finalConfirmed);Test.assert(!pair.join.finalConfirmed);
        Test.assertEqual(pair.host.battle["turn"],0);Test.assertEqual(pair.join.battle["turn"],0);
    }
    var idle=new BeastFriendLink(true,123,0,first,0);idle.tick(45001);Test.assertEqual(idle.phase,"CLOSING");
    idle.tick(48000);Test.assertEqual(idle.phase,"CLOSED");Test.assertEqual(idle.reason,"BATTLE TIMED OUT");
    var pair=new FriendLinkTestPair(first,first);pair.connect();pair.host.tick(pair.now+12001);
    Test.assertEqual(pair.host.phase,"CLOSED");Test.assertEqual(pair.host.reason,"CONNECTION LOST");
    var rollback=new BeastFriendLink(true,123,0,first,1000);rollback.tick(999);Test.assertEqual(rollback.phase,"CLOSED");return true;
}
(:test)
function friendLinkVersionInvalidSnapshotAndTurnTamperTest(logger){
    var first=FriendWireTestSupport.actor(0,0,0,0);
    var join=new BeastFriendLink(false,0,123,first,0);
    join.receive(BeastFriendWire.frame(345,0,1,0,0),0);Test.assertEqual(join.phase,"CLOSED");
    Test.assertEqual(join.reason,"INCOMPATIBLE VERSION");
    var host=new BeastFriendLink(true,345,0,first,0);
    host.receive(BeastFriendWire.frame(345,1,2,123,0),0);Test.assertEqual(host.phase,"EXCHANGE");
    var bytes=BeastFriendWire.actorBytes(first);bytes[0]=18;
    for(var i=0;i<6;i++){host.receive(BeastFriendWire.frame(345,2+i,4+i,bytes[i*2],bytes[i*2+1]),250+i*250);}
    Test.assertEqual(host.phase,"CLOSED");Test.assertEqual(host.reason,"INVALID OPPONENT");
    var pair=new FriendLinkTestPair(first,first);pair.connect();pair.host.choose(0,pair.now);pair.join.choose(0,pair.now);
    // Invalid received result must abort, never import attacker-provided HP.
    var valid=BeastBattleRules.pairedTurn(pair.join.battle,0,0);var forged=BeastFriendWire.resultBytes(valid,0,0);forged[2]=255;
    var next=pair.join.rx;
    for(var i=0;i<6;i++){pair.join.receive(BeastFriendWire.frame(pair.join.sid,next+i,13+i,forged[i*2],forged[i*2+1]),pair.now);}
    Test.assertEqual(pair.join.phase,"CLOSED");Test.assertEqual(pair.join.reason,"TURN MISMATCH");
    Test.assertEqual(pair.join.battle["turn"],0);return true;
}
(:test)
function friendLinkNoInputDeadlineAndNoRewardsTest(logger){
    var first=FriendWireTestSupport.actor(1,0,0,0);var pair=new FriendLinkTestPair(first,first);pair.connect();
    for(var i=0;i<400 && !pair.host.phase.equals("CLOSED");i++){pair.tick();}
    Test.assert(pair.host.phase.equals("CLOSED") || pair.host.phase.equals("CLOSING"));
    Test.assert(!pair.host.finalConfirmed);Test.assert(!pair.join.finalConfirmed);
    Test.assert(!pair.host.battle.hasKey("reward"));Test.assert(!pair.host.battle.hasKey("claimed"));
    Test.assertEqual(pair.host.battle["turn"],0);return true;
}
