using Toybox.Test;

(:test)
module FriendWireTestSupport {
    function actor(form,level,temper,bond){
        var stage=form<2?form+1:3+(form-2)%4;var family=form<2?0:1+((form-2)/4).toNumber();
        var rare=form>=2 && (form-2)%4==3?1:0;if(rare==1){stage=5;}
        var personality=[0,0,0,0];personality[temper]=1;
        var a=BeastBattleRules.fighter(stage,family,rare,bond,personality,level*BeastBattleData.LEVEL_XP,null);
        a["mastery"]=[0,9,10,999];return a;
    }
    function battle(form){return BeastBattleRules.create(1234,321,actor(form,4,3,80),actor((form+5)%18,7,0,30));}
}
(:test)
function friendFrameBoundariesAndMalformedTest(logger){
    var expected=[177,12,86,52,18,7,9,3];
    Test.assert(TestSupport.same(BeastFriendWire.frame(1193046,7,12,9,3),expected));
    Test.assert(TestSupport.same(BeastFriendWire.decode(expected),[1193046,7,12,9,3]));
    for(var side=0;side<2;side++){
        var packet=BeastFriendWire.frame(side==0?0:16777215,side==0?0:240,side==0?0:23,side==0?0:255,side==0?0:255);
        Test.assert(packet!=null);Test.assert(BeastFriendWire.decode(packet)!=null);
    }
    Test.assert(BeastFriendWire.frame(-1,0,0,0,0)==null);Test.assert(BeastFriendWire.frame(16777216,0,0,0,0)==null);
    Test.assert(BeastFriendWire.frame(1,241,0,0,0)==null);Test.assert(BeastFriendWire.frame(1,0,24,0,0)==null);
    Test.assert(BeastFriendWire.frame(1,0,0,256,0)==null);Test.assert(BeastFriendWire.frame(1,0,0,0,1.5)==null);
    Test.assert(BeastFriendWire.decode(null)==null);Test.assert(BeastFriendWire.decode([1,2])==null);
    for(var field=0;field<8;field++){
        var packet=[177,12,86,52,18,7,9,3];packet[field]=-1;Test.assert(BeastFriendWire.decode(packet)==null);
    }
    var wrong=[178,12,86,52,18,7,9,3];Test.assert(BeastFriendWire.decode(wrong)==null);return true;
}
(:test)
function friendActorRoundTripAndValidationTest(logger){
    for(var form=0;form<18;form++){
        for(var temper=0;temper<4;temper++){
            var level=temper%2==0?0:12;var a=FriendWireTestSupport.actor(form,level,temper,temper%2==0?0:100);
            var bytes=BeastFriendWire.actorBytes(a);Test.assert(bytes!=null);Test.assertEqual(bytes.size(),12);
            Test.assertEqual(bytes[0],form);Test.assertEqual(bytes[3],level);
            Test.assert(TestSupport.same(BeastFriendWire.actor(bytes),a));
        }
    }
    var pip=FriendWireTestSupport.actor(0,12,3,100);
    Test.assert(TestSupport.same(BeastFriendWire.actorBytes(pip),[0,100,3,12,0,0,9,0,10,0,231,3]));
    var base=[0,100,3,12,0,0,9,0,10,0,231,3];
    var fields=[0,1,2,3,5];var values=[18,101,4,13,4];
    for(var i=0;i<fields.size();i++){
        var bad=[];for(var b=0;b<12;b++){bad.add(base[b]);}bad[fields[i]]=values[i];Test.assert(BeastFriendWire.actor(bad)==null);
    }
    Test.assert(BeastFriendWire.actor([0,0])==null);Test.assert(BeastFriendWire.actor(null)==null);
    pip["hp"]--;Test.assert(BeastFriendWire.actorBytes(pip)==null);pip["hp"]++;
    pip["guard"]=1;Test.assert(BeastFriendWire.actorBytes(pip)==null);pip["guard"]=0;
    pip["power"]++;Test.assert(BeastFriendWire.actorBytes(pip)==null);pip["power"]--;
    pip["family"]=1;Test.assert(BeastFriendWire.actorBytes(pip)==null);return true;
}
(:test)
function friendPairedTurnPreservesAiAndPurityTest(logger){
    for(var form=0;form<18;form++){
        for(var slot=0;slot<4;slot++){
            for(var sample=0;sample<3;sample++){
                var state=FriendWireTestSupport.battle(form);state["seed"]=sample*2311+1;
                var before=BeastBattleRules.copy(state);
                var solo=BeastBattleRules.turn(state,slot);var paired=BeastBattleRules.pairedTurn(state,slot,BeastBattleRules.ai(state));
                Test.assert(TestSupport.same(solo,paired));Test.assert(TestSupport.same(state,before));
                paired["actors"][0]["mastery"][0]=88;Test.assertEqual(state["actors"][0]["mastery"][0],0);
            }
        }
    }
    var state=FriendWireTestSupport.battle(1);var before=BeastBattleRules.copy(state);
    Test.assert(!BeastBattleRules.availableAt(state,-1,0));Test.assert(!BeastBattleRules.availableAt(state,2,0));
    Test.assert(TestSupport.same(BeastBattleRules.pairedTurn(state,4,0),state));
    Test.assert(TestSupport.same(BeastBattleRules.pairedTurn(state,0,-1),state));
    Test.assert(TestSupport.same(before,state));return true;
}
(:test)
function friendPairedEffectsCooldownAndOutcomesTest(logger){
    var state=FriendWireTestSupport.battle(1);
    var guarded=BeastBattleRules.pairedTurn(state,1,0);var plain=BeastBattleRules.pairedTurn(state,2,0);
    Test.assert(guarded["actors"][0]["hp"]>plain["actors"][0]["hp"]);Test.assertEqual(guarded["events"][0]["effect"],1);
    var buffed=BeastBattleRules.pairedTurn(state,2,2);Test.assertEqual(buffed["actors"][0]["buff"],2);Test.assertEqual(buffed["actors"][1]["buff"],2);
    buffed=BeastBattleRules.pairedTurn(buffed,0,0);Test.assertEqual(buffed["actors"][0]["buff"],1);Test.assertEqual(buffed["actors"][1]["buff"],1);
    var signature=BeastBattleRules.pairedTurn(state,3,3);Test.assertEqual(signature["actors"][0]["cooldown"],2);Test.assertEqual(signature["actors"][1]["cooldown"],2);
    Test.assert(!BeastBattleRules.availableAt(signature,1,3));Test.assert(TestSupport.same(BeastBattleRules.pairedTurn(signature,0,3),signature));
    signature=BeastBattleRules.pairedTurn(signature,1,1);Test.assertEqual(signature["actors"][0]["cooldown"],1);
    signature=BeastBattleRules.pairedTurn(signature,1,1);Test.assert(BeastBattleRules.availableAt(signature,0,3));Test.assert(BeastBattleRules.availableAt(signature,1,3));
    var win=FriendWireTestSupport.battle(1);win["actors"][1]["hp"]=1;win=BeastBattleRules.pairedTurn(win,0,0);
    Test.assertEqual(win["status"],1);Test.assertEqual(win["events"].size(),1);
    var loss=FriendWireTestSupport.battle(1);loss["actors"][0]["hp"]=1;loss=BeastBattleRules.pairedTurn(loss,2,0);Test.assertEqual(loss["status"],2);
    var draw=FriendWireTestSupport.battle(1);
    for(var turn=0;turn<20;turn++){draw=BeastBattleRules.pairedTurn(draw,1,1);}
    Test.assertEqual(draw["status"],3);Test.assertEqual(draw["turn"],20);Test.assert(BeastBattleRules.importState(draw)!=null);return true;
}
(:test)
function friendAuthoritativeResultValidationTest(logger){
    for(var form=0;form<18;form++){
        var prior=FriendWireTestSupport.battle(form);var before=BeastBattleRules.copy(prior);
        var expected=BeastBattleRules.pairedTurn(prior,3,1);var encoded=BeastFriendWire.resultBytes(expected,3,1);
        Test.assert(TestSupport.same(BeastFriendWire.result(prior,encoded,1),expected));
        Test.assert(BeastFriendWire.result(prior,encoded,2)==null);
        for(var field=0;field<12;field++){
            var bad=[];for(var b=0;b<12;b++){bad.add(encoded[b]);}bad[field]=(bad[field]+1)%256;
            Test.assert(BeastFriendWire.result(prior,bad,1)==null);
        }
        Test.assert(TestSupport.same(prior,before));
    }
    Test.assert(BeastFriendWire.result(null,[0,0,0,0,0,0,0,0,0,0,0,0],0)==null);return true;
}
(:test)
function friendWireGoldenAndDigestOrderTest(logger){
    var actor=BeastBattleRules.fighter(1,0,0,0,[0,0,0,0],0,null);
    var state=BeastBattleRules.create(1,1,actor,actor);state=BeastBattleRules.pairedTurn(state,1,1);
    Test.assertEqual(BeastFriendWire.digest(state),20730);
    Test.assert(TestSupport.same(BeastFriendWire.resultBytes(state,1,1),[1,5,42,42,1,0,0,1,1,250,80,0]));
    var reordered={"uses"=>state["uses"],"events"=>state["events"],"actors"=>state["actors"],"status"=>state["status"],"turn"=>state["turn"],"seed"=>state["seed"],"id"=>state["id"],"v"=>state["v"]};
    Test.assertEqual(BeastFriendWire.digest(reordered),BeastFriendWire.digest(state));
    reordered["seed"]++;Test.assert(BeastFriendWire.digest(reordered)!=BeastFriendWire.digest(state));return true;
}
