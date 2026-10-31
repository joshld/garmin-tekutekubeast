using Toybox.Test;

(:test)
class FriendViewTestRadio {
    var opened=false;var status="RADIO OFF";var packet=null;var code=0;var host=false;var closes=0;var sends=0;
    function supported(){return true;}
    function open(isHost,number){host=isHost;code=number;opened=true;status="CONNECTED";return true;}
    function send(bytes){packet=[];for(var i=0;i<8;i++){packet.add(bytes[i]);}sends++;return opened;}
    function close(){opened=false;packet=null;status="RADIO OFF";closes++;}
}
(:test)
class FriendViewTestScreen extends BeastFriendView {
    var fakeNow=1000;
    function initialize(model){BeastFriendView.initialize(model);radio=new FriendViewTestRadio();}
    function battleClock(){return fakeNow;}
    // Rendering/art have separate SDK layout fixtures. This test isolates the
    // actual UI controller and avoids loading four fighter caches at once.
    function loadBattleArt(){}
}
(:test)
class FriendViewTestPair {
    var host;var join;var now=1000;
    function initialize(first,second){
        host=new FriendViewTestScreen(first);join=new FriendViewTestScreen(second);host.visible=true;join.visible=true;
        host.selectAction();host.stopBattleTimer();Test.assert(host.radio.opened);
        join.switchPage(1);Test.assertEqual(join.role,1);join.selectAction();Test.assert(join.entering);
        var code=host.pairCode;var values=[(code/1000).toNumber(),((code/100).toNumber())%10,((code/10).toNumber())%10,code%10];
        for(var i=0;i<4;i++){
            Test.assertEqual(join.digit,i);var presses=(values[i]-join.digits[i]+10)%10;
            for(var j=0;j<presses;j++){join.switchPage(1);}join.selectAction();
        }
        join.stopBattleTimer();Test.assert(join.radio.opened);Test.assertEqual(join.pairCode,host.pairCode);
        Test.assertEqual(join.radio.code,host.radio.code);Test.assert(host.radio.host);Test.assert(!join.radio.host);
    }
    function tick(){
        now+=250;host.fakeNow=now;join.fakeNow=now;host.refresh();join.refresh();
        if(host.radio.opened && join.radio.opened && host.radio.packet!=null){join.receiveFriend(host.radio.packet);}
        if(host.radio.opened && join.radio.opened && join.radio.packet!=null){host.receiveFriend(join.radio.packet);}
    }
    function until(first,second,limit){
        for(var i=0;i<limit;i++){if(host.link.phase.equals(first) && join.link.phase.equals(second)){return true;}tick();}
        return host.link.phase.equals(first) && join.link.phase.equals(second);
    }
    function ready(){
        Test.assert(until("READY","READY",200));host.selectAction();join.selectAction();
        host.selectAction();join.selectAction();Test.assert(host.link.localReady);Test.assert(join.link.localReady);
        Test.assert(until("PLAY","PLAY",80));
    }
}
(:test)
function friendViewHostJoinButtonsAndTurnPresentationTest(logger){
    var first=FriendModelTestSupport.pet();var second=FriendModelTestSupport.pet();second.data["stageFloor"]=3;second.data["family"]=2;second.commit();
    var pet=first.store.copy(first.store.read("v4"));var journal=first.store.copy(first.store.read("battle.v1"));var cache=first.store.copy(first.battleData);var writes=first.store.writes;
    var pair=new FriendViewTestPair(first,second);pair.ready();
    Test.assertEqual(pair.host.battlePhase,1);Test.assertEqual(pair.join.battlePhase,1);
    pair.host.switchPage(1);pair.host.switchPage(1);Test.assertEqual(pair.host.moveChoice,2);pair.host.selectAction();
    var sequence=pair.host.link.tx;pair.host.selectAction();pair.host.switchPage(1);
    Test.assertEqual(pair.host.link.tx,sequence);Test.assertEqual(pair.host.moveChoice,2);Test.assertEqual(pair.host.link.choice,2);
    pair.join.switchPage(1);Test.assertEqual(pair.join.moveChoice,1);pair.join.selectAction();pair.join.selectAction();
    Test.assert(pair.until("PRESENT","PRESENT",200));
    Test.assertEqual(pair.host.battle["turn"],1);Test.assertEqual(pair.join.battle["turn"],1);
    Test.assertEqual(pair.host.battle["actors"][0]["form"],pair.join.battle["actors"][1]["form"]);
    Test.assertEqual(pair.host.battle["actors"][1]["form"],pair.join.battle["actors"][0]["form"]);
    Test.assertEqual(pair.host.battle["actors"][0]["hp"],pair.join.battle["actors"][1]["hp"]);
    Test.assertEqual(pair.host.battle["actors"][1]["hp"],pair.join.battle["actors"][0]["hp"]);
    Test.assertEqual(pair.host.burst,4);Test.assertEqual(pair.host.eventIndex(),0);Test.assert(!pair.host.resultVisible());
    var hp=pair.host.displayHp(0);pair.host.selectAction();Test.assertEqual(pair.host.burst,4);Test.assertEqual(pair.host.battle["turn"],1);
    // Every displayed action/result interval is driven through refresh().
    var results=0;var previous=pair.host.burst;
    for(var i=0;i<30 && !pair.host.link.phase.equals("PLAY");i++){
        pair.tick();if(pair.host.burst!=previous){results++;previous=pair.host.burst;}
    }
    Test.assertEqual(results,4);Test.assertEqual(pair.host.link.phase,"PLAY");Test.assertEqual(pair.host.burst,0);
    Test.assertEqual(pair.host.displayHp(0),hp);Test.assert(pair.until("PLAY","PLAY",12));
    pair.host.selectAction();pair.join.switchPage(3);pair.join.selectAction();
    Test.assert(pair.until("PRESENT","PRESENT",200));Test.assertEqual(pair.host.battle["turn"],2);
    Test.assertEqual(pair.host.displayHp(0),hp);Test.assert(pair.host.battle["actors"][0]["hp"]<hp);
    Test.assert(pair.until("PLAY","PLAY",32));Test.assertEqual(pair.host.displayHp(0),pair.host.battle["actors"][0]["hp"]);
    Test.assertEqual(pair.host.displayHp(0),pair.join.displayHp(1));
    Test.assert(TestSupport.same(pair.host.link.battle,pair.join.link.battle));
    pair.host.onHide();pair.join.onHide();
    Test.assert(!pair.host.radio.opened);Test.assert(pair.host.battleTimer==null);
    Test.assert(!pair.join.radio.opened);Test.assert(pair.join.battleTimer==null);
    Test.assertEqual(pair.host.link.phase,"CLOSED");Test.assertEqual(pair.join.link.phase,"CLOSED");
    FriendModelTestSupport.unchanged(first,pet,journal,cache,writes+1);return true;
}
(:test)
function friendViewInterruptionClosesRadioAndFreezesControllerTest(logger){
    var first=FriendModelTestSupport.pet();var second=FriendModelTestSupport.pet();
    var pet=first.store.copy(first.store.read("v4"));var journal=first.store.copy(first.store.read("battle.v1"));var cache=first.store.copy(first.battleData);var writes=first.store.writes;
    var pair=new FriendViewTestPair(first,second);pair.ready();
    pair.host.selectAction();Test.assertEqual(pair.host.link.choice,0);
    pair.host.onHide();Test.assert(pair.host.wasHidden);Test.assert(!pair.host.visible);
    Test.assertEqual(pair.host.link.phase,"CLOSED");Test.assertEqual(pair.host.link.reason,"INTERRUPTED - RECONNECT");
    Test.assert(pair.host.battleTimer==null);Test.assert(!pair.host.radio.opened);
    var revision=pair.host.link.changed;var count=pair.host.radio.sends;var turns=pair.host.link.battle["turn"];
    pair.host.fakeNow+=2000;pair.host.refresh();pair.host.selectAction();pair.host.receiveFriend(pair.join.radio.packet);
    Test.assertEqual(pair.host.link.changed,revision);Test.assertEqual(pair.host.radio.sends,count);Test.assertEqual(pair.host.link.battle["turn"],turns);
    pair.join.onHide();FriendModelTestSupport.unchanged(first,pet,journal,cache,writes+1);return true;
}
