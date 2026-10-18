using Toybox.Test;
using Toybox.Lang;

(:test)
function battlePortableRewardGoldenTest(logger){
    var rows=RuleVectors.battle_rewards();
    for(var i=0;i<rows.size();i++){
        var r=rows[i];var eligible=BeastBattleRules.rewardEligible(r["status"],r["turn"],r["practice"],r["rewarded"]);
        Test.assertEqual(eligible,r["eligible"]);
        Test.assertEqual(eligible?BeastBattleRules.xpReward({"status"=>r["status"]}):0,r["xp"]);
    }
    return true;
}

(:test)
function battlePortableStatsGoldenTest(logger){
    var rows=RuleVectors.battle_stats();
    for(var i=0;i<rows.size();i++){
        var r=rows[i];var actor=BeastBattleRules.fighter(r["stage"],r["family"],r["rare"],r["friendship"],r["personality"],r["xp"],r["mastery"]);
        Test.assert(TestSupport.same(actor,r["expected"]));
    }
    return true;
}

(:test)
function battlePortableReplayGoldenTest(logger){
    var rows=RuleVectors.battle_replay();
    for(var i=0;i<rows.size();i++){
        var row=rows[i];var state=BeastBattleRules.importState(row["initial"]);Test.assert(state!=null);
        if(row.hasKey("rng")){for(var r=1;r<row["rng"].size();r++){Test.assertEqual(BeastBattleRules.nextSeed(row["rng"][r-1]),row["rng"][r]);}}
        for(var t=0;t<row["commands"].size();t++){
            logger.debug(row["id"]+" turn "+t+" AI "+BeastBattleRules.ai(state));
            var before=new BeastStore().copy(state);Test.assertEqual(BeastBattleRules.ai(state),row["ai"][t]);
            var next=BeastBattleRules.turn(state,row["commands"][t]);Test.assert(TestSupport.same(before,state));
            Test.assert(TestSupport.same(next,row["states"][t]));
            // Object snapshot boundary models JSON save/load without a platform
            // codec or reference engine. Every intermediate state must resume.
            state=BeastBattleRules.importState(BeastBattleRules.exportState(next));
            Test.assert(state!=null);Test.assert(TestSupport.same(state,next));
        }
        Test.assertEqual(BeastBattleRules.xpReward(state),row["xp"]);
        Test.assert(TestSupport.same(BeastBattleRules.masteryReward(state),row["mastery"]));
    }
    return true;
}
(:test)
function battleSnapshotVersionAndTypeTest(logger){
    var s=RuleVectors.battle_replay()[0]["initial"];var copy=new BeastStore().copy(s);
    s["practice"]=true;Test.assert(BeastBattleRules.importState(s)==null);
    Test.assert(TestSupport.same(BeastBattleRules.exportState(s),copy));s.remove("practice");
    s["v"]=2;Test.assert(BeastBattleRules.importState(s)==null);Test.assert(BeastBattleRules.exportState(s)==null);
    Test.assert(BeastBattleRules.turn(s,0)==null);Test.assert(!BeastBattleRules.available(s,0));s["v"]=1;
    s["seed"]=1.5;Test.assert(BeastBattleRules.importState(s)==null);
    Test.assert(BeastBattleRules.exportState(s)==null);s["seed"]=-1;Test.assert(BeastBattleRules.exportState(s)==null);
    s["seed"]=65521;Test.assert(BeastBattleRules.exportState(s)==null);
    Test.assert(BeastBattleRules.exportState({"v"=>1})==null);
    s["seed"]=42.0;var normalized=BeastBattleRules.importState(s);Test.assert(normalized!=null);
    Test.assert(!(normalized["seed"] instanceof Lang.Float));s["seed"]=42;
    s["id"]=2147483647;Test.assert(BeastBattleRules.importState(s)!=null);
    s["id"]=2147483648l;Test.assert(BeastBattleRules.importState(s)==null);
    Test.assert(BeastBattleRules.importState(null)==null);Test.assert(BeastBattleRules.importState("v1")==null);
    Test.assert(TestSupport.same(copy,BeastBattleRules.turn(copy,0.5)));return true;
}
(:test)
function battleSnapshotSemanticTest(logger){
    var source=RuleVectors.battle_replay()[0]["initial"];var store=new BeastStore();var s=store.copy(source);
    s["uses"][0]=1;Test.assert(BeastBattleRules.importState(s)==null);s=store.copy(source);
    s["actors"][0]["hp"]=71;Test.assert(BeastBattleRules.importState(s)==null);s=store.copy(source);
    s["actors"][0]["form"]=17;Test.assert(BeastBattleRules.importState(s)==null);s=store.copy(source);
    s["actors"][0]["mastery"]=[0,0];Test.assert(BeastBattleRules.importState(s)==null);s=store.copy(source);
    s["actors"][1]=null;Test.assert(BeastBattleRules.importState(s)==null);s=store.copy(source);
    s["status"]=1;Test.assert(BeastBattleRules.importState(s)==null);
    s=store.copy(RuleVectors.battle_replay()[0]["states"][0]);s["events"][1]["move"]=71;
    Test.assert(BeastBattleRules.importState(s)==null);s=store.copy(source);
    var restored=BeastBattleRules.importState(s);restored["actors"][0]["mastery"][0]=99;
    Test.assert(TestSupport.same(s,source));return true;
}

(:test)
function battleViewLifecycleTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=2;var v=new BeastBattleView(s);
    v.burst=8;var writes=s.store.writes;v.refresh();Test.assertEqual(v.burst,8);
    Test.assert(v.battleTimer==null);Test.assertEqual(s.store.writes,writes);
    v.battleVisible=true;v.battle=null;v.refresh();Test.assertEqual(v.burst,0);
    Test.assertEqual(v.battleRedraws,0);v.onHide();Test.assert(!v.battleVisible);Test.assert(v.battleTimer==null);return true;
}

(:test)
function battleMoveHintsAndResumedDiscoveryTest(logger){
    var s=TestSupport.fixture();s.data["stageFloor"]=1;s.data["sleepMode"]=2;s.commit();
    var v=new BeastBattleView(s);Test.assertEqual(v.fight.battleQueueCount(),1);
    // A fresh foreground reconciliation must be observed by the existing view.
    s.observe(s.today(),10000);s.commit();v.onShow();
    Test.assertEqual(v.fight.battleQueueCount(),3);v.battle=v.fight.beginBattle();v.battlePhase=1;
    v.moveChoice=3;v.battle=v.fight.battleTurn(3);
    Test.assert(v.moveHint().equals("Ready in 2 moves"));var turn=v.battle["turn"];var writes=s.store.writes;
    v.selectAction();Test.assertEqual(v.battlePhase,1);Test.assertEqual(v.battle["turn"],turn);
    Test.assertEqual(s.store.writes,writes);Test.assert(v.battleNotice.equals(""));
    v.moveChoice=1;Test.assert(v.moveHint().equals("Soften next hit"));
    v.moveChoice=2;Test.assert(v.moveHint().equals("Boost next 2 hits"));v.onHide();return true;
}

(:test)
function battleSeparateSaveAndDevTest(logger){
    var s=TestSupport.fixture();s.data["stageFloor"]=1;s.data["sleepMode"]=2;s.commit();
    var pet=s.store.copy(s.store.read("v4"));var fight=new BeastBattle(s);Test.assertEqual(fight.battleQueueCount(),1);
    Test.assertEqual(fight.battleXp(),0);Test.assertEqual(fight.data["mastery"].size(),72);
    Test.assert(TestSupport.same(pet,s.store.read("v4")));var writes=s.store.writes;
    var again=new BeastBattle(s);Test.assertEqual(s.store.writes,writes);Test.assertEqual(again.battleQueueCount(),1);
    var real=s.store.copy(s.store.read("battle.v1"));var dev=s.enableDev();var lab=new BeastBattle(dev);
    lab.beginBattle();lab.data["active"]["actors"][1]["hp"]=1;lab.battleTurn(0);lab.finishBattle();
    Test.assert(lab.battleXp()>0);Test.assert(TestSupport.same(real,s.store.read("battle.v1")));
    Test.assert(TestSupport.same(pet,s.store.read("v4")));Test.assertEqual(fight.battleXp(),0);return true;
}
(:test)
function battleStepCatchupAndDedupTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=2;var fight=new BeastBattle(s);s.observe(s.today(),10000);
    var xp=s.xp();fight.discover();Test.assertEqual(fight.battleQueueCount(),3);Test.assertEqual(fight.data["stepOffers"],2);
    var writes=s.store.writes;fight.discover();Test.assertEqual(s.store.writes,writes);Test.assertEqual(s.xp(),xp);
    while(fight.declineEncounter()){}s.observe(s.today(),50000);fight.discover();Test.assertEqual(fight.battleQueueCount(),0);
    Test.assertEqual(fight.data["stepMark"],20);fight.discover();Test.assertEqual(fight.battleQueueCount(),0);
    var legacy=TestSupport.fixture();legacy.observe(legacy.today(),50000);var fresh=new BeastBattle(legacy);
    Test.assertEqual(fresh.battleQueueCount(),1);Test.assertEqual(fresh.data["stepMark"],20);return true;
}
(:test)
function battleAccessibleQueueAndRollbackTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=2;var fight=new BeastBattle(s);Test.assertEqual(s.xp(),0l);
    fight.declineEncounter();s.data["careToday"]=100;fight.discover();Test.assertEqual(fight.battleQueueCount(),1);
    s.data["encounters"]=1;fight.discover();Test.assertEqual(fight.battleQueueCount(),2);
    var serial=fight.data["serial"];fight.postponeBattle();fight.discover();Test.assertEqual(fight.data["serial"],serial);
    s.data["careToday"]=300;s.data["encounters"]=100;fight.discover();Test.assertEqual(fight.battleQueueCount(),4);
    while(fight.declineEncounter()){}fight.discover();Test.assertEqual(fight.battleQueueCount(),0);
    s.testNow-=86400;fight.discover();Test.assertEqual(fight.battleQueueCount(),0);Test.assertEqual(s.xp(),0l);
    s.testNow+=2*86400;s.data["careToday"]=0;fight.discover();Test.assertEqual(fight.battleQueueCount(),1);return true;
}
(:test)
function battleResumeClaimAndPracticeTest(logger){
    var s=TestSupport.fixture();s.data["stageFloor"]=1;s.data["sleepMode"]=2;s.commit();
    var pet=s.store.copy(s.store.read("v4"));var fight=new BeastBattle(s);fight.beginBattle();fight.battleTurn(1);
    var pending=fight.battleSession();pending["actors"][0]["hp"]=0;Test.assert(fight.battleSession()["actors"][0]["hp"]>0);
    pending=fight.battleSession();fight.postponeBattle();s.battleData=null;var resumed=new BeastBattle(s);
    Test.assert(TestSupport.same(pending,resumed.battleSession()));Test.assert(TestSupport.same(pending,resumed.beginBattle()));
    resumed.data["active"]["actors"][1]["hp"]=1;resumed.battleTurn(0);var outcome=resumed.finishBattle();
    Test.assertEqual(resumed.battleXp(),12);Test.assertEqual(resumed.battleMastery(0),1);
    var writes=s.store.writes;Test.assert(resumed.finishBattle().equals(outcome));Test.assertEqual(s.store.writes,writes);
    s.battleData=null;var reload=new BeastBattle(s);reload.finishBattle();Test.assertEqual(reload.battleXp(),12);
    var mastery=s.store.copy(reload.data["mastery"]);reload.practiceBattle();reload.data["active"]["actors"][1]["hp"]=1;
    reload.battleTurn(0);reload.finishBattle();Test.assertEqual(reload.battleXp(),12);Test.assert(TestSupport.same(mastery,reload.data["mastery"]));
    Test.assert(TestSupport.same(pet,s.store.read("v4")));return true;
}
(:test)
function battleSleepAndRewardLimitsTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=2;var fight=new BeastBattle(s);Test.assert(fight.beginBattle()==null);
    s.data["stageFloor"]=1;s.rest();Test.assert(fight.beginBattle()==null);Test.assert(fight.practiceBattle()==null);s.wakeUp();
    fight.beginBattle();s.rest();var before=s.store.copy(fight.data);var writes=s.store.writes;
    Test.assert(fight.battleTurn(0)==null);Test.assert(TestSupport.same(before,fight.data));Test.assertEqual(s.store.writes,writes);s.wakeUp();
    s.rest();fight.data["active"]["status"]=1;fight.data["active"]["turn"]=1;var blocked=s.store.copy(fight.data);
    Test.assert(fight.finishBattle().equals("Beast is asleep."));Test.assert(TestSupport.same(blocked,fight.data));
    fight.data["active"]["status"]=0;fight.data["active"]["turn"]=0;s.wakeUp();
    for(var i=0;i<6;i++){
        if(i>0){fight.offer(0);fight.beginBattle();}fight.data["active"]["actors"][1]["hp"]=1;fight.battleTurn(0);fight.finishBattle();
    }
    Test.assertEqual(fight.data["rewarded"],5);Test.assertEqual(fight.battleXp(),60);Test.assertEqual(s.xp(),0l);
    Test.assertEqual(s.number("games"),0);Test.assertEqual(s.number("adventure"),0);return true;
}

(:test)
function battleMidnightClaimAndCareRolloverTest(logger){
    var s=TestSupport.fixture();s.data["stageFloor"]=1;s.data["sleepMode"]=2;s.commit();
    var pet=s.store.copy(s.store.read("v4"));var fight=new BeastBattle(s);fight.beginBattle();
    fight.data["active"]["actors"][1]["hp"]=1;fight.battleTurn(0);
    fight.data["rewarded"]=5;fight.commit();s.data["careToday"]=300;
    s.testNow+=86400;var day=s.today();var outcome=fight.finishBattle();
    Test.assertEqual(fight.data["day"],day);Test.assertEqual(s.number("careToday"),0);
    Test.assertEqual(fight.battleQueueCount(),1);Test.assertEqual(fight.data["rewarded"],1);
    Test.assertEqual(fight.battleXp(),12);Test.assert(outcome.equals("+12 BATTLE XP"));
    // Lazy pet catch-up must not introduce a second canonical save transaction.
    Test.assert(TestSupport.same(pet,s.store.read("v4")));var writes=s.store.writes;
    fight.discover();Test.assertEqual(s.store.writes,writes);
    // Claimed results stay idempotent even if reopened on a later local day.
    s.testNow+=86400;Test.assert(fight.finishBattle().equals(outcome));
    Test.assertEqual(s.store.writes,writes);Test.assertEqual(fight.data["rewarded"],1);
    Test.assertEqual(fight.data["day"],day);Test.assertEqual(fight.battleXp(),12);
    s.testNow-=2*86400;fight.discover();Test.assertEqual(fight.data["day"],day);
    Test.assertEqual(fight.data["rewarded"],1);Test.assertEqual(fight.battleXp(),12);return true;
}
(:test)
function battleTerminalBeforeClaimReloadTest(logger){
    var s=TestSupport.fixture();s.data["stageFloor"]=1;s.data["sleepMode"]=2;s.commit();
    var fight=new BeastBattle(s);fight.beginBattle();fight.data["active"]["actors"][1]["hp"]=1;fight.battleTurn(0);
    var terminal=fight.battleSession();Test.assertEqual(terminal["status"],1);Test.assert(!terminal["claimed"]);
    Test.assertEqual(fight.battleXp(),0);s.battleData=null;var reload=new BeastBattle(s);
    Test.assert(TestSupport.same(terminal,reload.battleSession()));Test.assertEqual(reload.battleXp(),0);
    Test.assert(reload.finishBattle().equals("+12 BATTLE XP"));var writes=s.store.writes;
    s.battleData=null;var claimed=new BeastBattle(s);claimed.finishBattle();
    Test.assertEqual(claimed.battleXp(),12);Test.assertEqual(claimed.data["rewarded"],1);
    Test.assertEqual(s.store.writes,writes);return true;
}
(:test)
function battleBalanceSurveyTest(logger){
    // Diagnostic native-engine survey, not a substitute for button playtesting.
    // Identical seed/matchups compare direct, signature-cycle and buff-cycle.
    var totals=[[0,0,0,0,20,0],[0,0,0,0,20,0],[0,0,0,0,20,0]];
    for(var form=0;form<18;form++){
        var stage=form<2?form+1:3+BeastBattleRules.min(2,(form-2)%4);
        var family=form<2?0:1+((form-2)/4).toNumber();var rare=form>=2 && (form-2)%4==3?1:0;
        for(var sample=0;sample<8;sample++){
            var seed=17+sample*719;var temper=[0,0,0,0];temper[sample%4]=1;
            var p=BeastBattleRules.fighter(stage,family,rare,60,temper,0,null);
            var e=BeastBattleRules.fighter(stage,family==0?0:1+sample%4,0,30,temper,0,null);
            var original=new BeastStore().copy([p,e]);
            for(var strategy=0;strategy<3;strategy++){
                var state=BeastBattleRules.create(1,seed,p,e);
                while(state["status"]==0){
                    var slot=0;
                    if(strategy==1 && BeastBattleRules.available(state,3)){slot=3;}
                    if(strategy==2 && state["actors"][0]["buff"]==0){slot=2;}
                    state=BeastBattleRules.turn(state,slot);
                    Test.assert(state["turn"]<=20);
                    for(var actor=0;actor<2;actor++){
                        Test.assert(state["actors"][actor]["hp"]>=0);
                        Test.assert(state["actors"][actor]["hp"]<=state["actors"][actor]["maxHp"]);
                    }
                }
                Test.assert(BeastBattleRules.exportState(state)!=null);
                Test.assert(TestSupport.same(original,[p,e]));
                var row=totals[strategy];row[state["status"]-1]++;row[3]+=state["turn"];
                row[4]=BeastBattleRules.min(row[4],state["turn"]);row[5]=BeastBattleRules.max(row[5],state["turn"]);
            }
        }
    }
    var names=["direct","signature-cycle","buff-cycle"];
    for(var i=0;i<3;i++){
        var row=totals[i];Test.assertEqual(row[0]+row[1]+row[2],144);
        logger.debug("BATTLE_BALANCE "+names[i]+": wins="+row[0]+" losses="+row[1]+" draws="+row[2]+" turns="+row[3]+" range="+row[4]+"-"+row[5]+" matches=144");
    }
    return true;
}
(:test)
function battleRosterGoldenTest(logger){
    var rows=RuleVectors.battle();var seen={};var count=0;
    for(var i=0;i<rows.size();i++){
        var row=rows[i];var form=BeastBattleMoves.form(row["stage"],row["family"],row["rare"]);
        Test.assertEqual(form,row["form"]);var names=BeastBattleMoves.names(form);Test.assertEqual(names.size(),4);
        for(var slot=0;slot<4;slot++){
            var id=BeastBattleMoves.id(form,slot);Test.assertEqual(id,form*4+slot);
            Test.assert(!seen.hasKey(id));seen[id]=true;count++;
            Test.assert(names[slot].equals(row["names"][slot]));Test.assert(BeastBattleMoves.name(id).equals(row["names"][slot]));
            Test.assertEqual(BeastBattleMoves.role(id),slot);
        }
    }
    Test.assertEqual(count,72);Test.assertEqual(BeastBattleMoves.form(0,0,0),-1);
    Test.assert(BeastBattleRules.fighter(0,0,0,0,null,0,null)==null);
    Test.assertEqual(BeastBattleMoves.names(-1).size(),0);
    for(var family=1;family<=4;family++){
        Test.assertEqual(BeastBattleMoves.form(3,family,1),BeastBattleMoves.form(3,family,0));
        Test.assertEqual(BeastBattleMoves.form(4,family,1),BeastBattleMoves.form(4,family,0));
    }
    return true;
}
(:test)
function battleReplayPurityAndResumeTest(logger){
    var p=BeastBattleRules.fighter(3,1,0,80,[3,2,1,0],120,null);
    var foe=BeastBattleRules.fighter(3,2,0,40,[0,3,1,2],80,null);var saved=new BeastStore().copy(p);
    var a=BeastBattleRules.create(17,12345,p,foe);var b=new BeastStore().copy(a);
    Test.assert(TestSupport.same(p,saved));a["actors"][0]["mastery"][0]=1;Test.assertEqual(p["mastery"][0],0);
    a["actors"][0]["mastery"][0]=0;
    for(var turn=0;turn<20 && a["status"]==0;turn++){
        var slot=turn%4;if(!BeastBattleRules.available(a,slot)){slot=0;}
        var before=new BeastStore().copy(a);var next=BeastBattleRules.turn(a,slot);
        Test.assert(TestSupport.same(before,a));b=BeastBattleRules.turn(b,slot);Test.assert(TestSupport.same(next,b));
        a=new BeastStore().copy(next); // plain persisted snapshot needs no VM-specific reconstruction
        Test.assertEqual(a["v"],1);Test.assertEqual(a["id"],17);Test.assert(a["seed"]>=0 && a["seed"]<65521);
        Test.assert(a["events"].size()>=1 && a["events"].size()<=2);
        for(var actor=0;actor<2;actor++){Test.assert(a["actors"][actor]["hp"]>=0 && a["actors"][actor]["hp"]<=a["actors"][actor]["maxHp"]);}
    }
    Test.assert(a["status"]>0);Test.assert(a["turn"]<=20);
    Test.assert(TestSupport.same(a,BeastBattleRules.turn(a,0)));return true;
}
(:test)
function battleEffectsAndInfluenceTest(logger){
    var expected=RuleVectors.battle()[0]["probe"];
    var p=BeastBattleRules.fighter(3,0,0,0,[3,0,0,0],0,null);var foe=BeastBattleRules.fighter(3,0,0,0,[3,0,0,0],0,null);
    var normal=BeastBattleRules.create(1,42,p,foe);BeastBattleRules.act(normal,0,0);var damage=normal["events"][0]["damage"];
    Test.assertEqual(normal["seed"],expected["nextSeed"]);Test.assertEqual(damage,expected["damage"]);
    var guarded=BeastBattleRules.create(1,42,p,foe);BeastBattleRules.act(guarded,1,1);BeastBattleRules.act(guarded,0,0);
    Test.assertEqual(guarded["events"][1]["damage"],expected["guarded"]);Test.assertEqual(guarded["actors"][1]["guard"],0);
    var buffed=BeastBattleRules.create(1,42,p,foe);BeastBattleRules.act(buffed,0,2);BeastBattleRules.act(buffed,0,0);
    Test.assertEqual(buffed["events"][1]["damage"],expected["buffed"]);Test.assertEqual(buffed["actors"][0]["buff"],1);
    var bonded=BeastBattleRules.create(1,42,p,foe);bonded["actors"][0]["friendship"]=100;BeastBattleRules.act(bonded,0,0);
    Test.assertEqual(bonded["events"][0]["damage"],expected["bonded"]);
    var bold=BeastBattleRules.create(1,42,p,foe);bold["actors"][0]["temper"]=1;BeastBattleRules.act(bold,0,0);
    Test.assertEqual(bold["events"][0]["damage"],expected["bold"]);
    var trained=BeastBattleRules.create(1,42,p,foe);trained["actors"][0]["mastery"][0]=30;BeastBattleRules.act(trained,0,0);
    Test.assertEqual(trained["events"][0]["damage"],expected["trained"]);
    Test.assert(BeastBattleRules.affinity(1,3)>0);Test.assert(BeastBattleRules.affinity(3,1)<0);
    Test.assertEqual(BeastBattleRules.affinity(0,3),0);
    var adult=BeastBattleRules.fighter(3,1,0,0,[0,0,0,0],0,null);var legend=BeastBattleRules.fighter(5,1,0,0,[0,0,0,0],0,null);
    Test.assert(legend["maxHp"]>adult["maxHp"]);Test.assert(legend["power"]>adult["power"]);return true;
}
(:test)
function battleAiCooldownAndBoundsTest(logger){
    var p=BeastBattleRules.fighter(5,1,0,50,[0,0,0,1],0,null);var foe=BeastBattleRules.fighter(5,2,0,50,[0,1,0,0],0,null);
    var state=BeastBattleRules.create(2,123,p,foe);state["actors"][0]["hp"]=10000;state["actors"][1]["hp"]=10000;
    state=BeastBattleRules.turn(state,3);Test.assertEqual(state["actors"][0]["cooldown"],2);Test.assert(!BeastBattleRules.available(state,3));
    Test.assert(TestSupport.same(state,BeastBattleRules.turn(state,3)));Test.assert(TestSupport.same(state,BeastBattleRules.turn(state,-1)));
    Test.assert(TestSupport.same(state,BeastBattleRules.turn(state,4)));state=BeastBattleRules.turn(state,0);
    Test.assert(!BeastBattleRules.available(state,3));state=BeastBattleRules.turn(state,0);Test.assert(BeastBattleRules.available(state,3));
    for(var seed=0;seed<40;seed++){
        state["seed"]=seed;state["actors"][1]["cooldown"]=2;var before=new BeastStore().copy(state);var choice=BeastBattleRules.ai(state);
        Test.assert(choice>=0 && choice<3);Test.assert(TestSupport.same(before,state));
    }
    while(state["status"]==0){state=BeastBattleRules.turn(state,1);}
    Test.assertEqual(state["turn"],20);Test.assertEqual(state["status"],3);return true;
}
(:test)
function battleProgressionBoundsTest(logger){
    Test.assertEqual(BeastBattleRules.level(-80),0);Test.assertEqual(BeastBattleRules.level(79),0);
    Test.assertEqual(BeastBattleRules.level(80),1);Test.assertEqual(BeastBattleRules.level(99999),12);
    var mastery=[];for(var n=0;n<72;n++){mastery.add(99999);}
    var p=BeastBattleRules.fighter(3,1,0,900,[0,0,0,1],99999,mastery);Test.assertEqual(p["friendship"],100);
    Test.assertEqual(p["mastery"][0],999);var foe=BeastBattleRules.fighter(1,0,0,0,[0,0,0,0],0,null);
    var state=BeastBattleRules.create(3,0,p,foe);Test.assertEqual(BeastBattleRules.xpReward(state),0);
    var empty=BeastBattleRules.masteryReward(state);Test.assertEqual(empty.size(),72);
    for(var i=0;i<72;i++){Test.assertEqual(empty[i],0);}
    var xp=[0,12,5,7];
    for(var status=1;status<=3;status++){
        state["status"]=status;state["uses"]=[20,2,1,0];var before=new BeastStore().copy(state);
        Test.assertEqual(BeastBattleRules.xpReward(state),xp[status]);var increments=BeastBattleRules.masteryReward(state);
        for(var id=0;id<72;id++){var slot=id-p["form"]*4;Test.assertEqual(increments[id],slot==0?3:(slot==1?2:(slot==2?1:0)));}
        Test.assert(TestSupport.same(before,state));
    }
    return true;
}

(:test)
function sleepingActionsNoMutationTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=2;s.data["poop"]=1;s.data["items"][0]=3;s.rest();
    var before=s.store.copy(s.data);var writes=s.store.writes;
    Test.assert(!s.feedFood(true));Test.assert(!s.feedFood(false));Test.assert(!s.pat());Test.assert(!s.clean());
    for(var game=0;game<3;game++){Test.assert(s.beginSession(game)==null);}
    Test.assert(s.gameReward(true,0).equals("Beast is asleep."));Test.assert(!s.useItem(0));Test.assert(!s.useItem(1));
    Test.assert(s.explore(0).equals("Beast is asleep."));s.rest();
    Test.assert(TestSupport.same(before,s.data));Test.assertEqual(s.store.writes,writes);
    var v=new TekuTekuBeastView();v.beast=s;var names=["Feed","Pat","Play","Clean"];
    var cue=FeedbackManager.lastCue;
    for(var action=0;action<names.size();action++){
        v.openMenu("Actions");var found=false;
        for(var i=0;i<v.rows.size();i++){if(v.rows[i].equals(names[action])){v.selection=i;found=true;break;}}
        Test.assert(found);v.selectAction();Test.assert(v.notice.equals("Beast is asleep."));
        Test.assert(v.visualState().equals("sleep"));Test.assert(TestSupport.same(before,s.data));
    }
    v.openMenu("Feed");v.selectAction();Test.assert(v.notice.equals("Beast is asleep."));
    Test.assertEqual(FeedbackManager.lastCue,cue);v.openMenu("Actions");Test.assert(v.rows[8].equals("Wake Up"));
    v.selection=8;v.selectAction();Test.assert(!s.isSleeping());Test.assert(v.notice.equals("Waking up."));
    Test.assert(s.feedFood(true));Test.assert(s.pat());Test.assert(s.clean());return true;
}
(:test)
function napGrumpGoldenTest(logger){
    var rows=RuleVectors.sleep();
    for(var i=0;i<rows.size();i++){
        var row=rows[i];Test.assertEqual(BeastSleep.napAnnoyance(row["seconds"]),row["annoyance"]);
        var s=TestSupport.fixture();s.data["sleepMode"]=2;s.rest();var personality=s.store.copy(s.data["personality"]);
        var joy=s.number("happiness");s.testNow+=row["seconds"];
        if(row["seconds"]>=3600){var before=s.store.copy(s.data);Test.assert(!s.wakeUp());Test.assert(TestSupport.same(before,s.data));}
        else{Test.assert(s.wakeUp());Test.assertEqual(s.grump(),row["annoyance"]);Test.assertEqual(s.happiness(),joy-row["annoyance"]);}
        Test.assert(!s.isSleeping());Test.assertEqual(s.number("happiness"),joy);
        Test.assert(TestSupport.same(personality,s.data["personality"]));var writes=s.store.writes;
        s.testNow+=300;Test.assertEqual(s.grump(),0);Test.assertEqual(s.happiness(),joy);Test.assertEqual(s.store.writes,writes);
    }
    return true;
}
(:test)
function scheduledWakeReopenAndLightingTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=1;s.data["bedMinute"]=1320;s.data["wakeMinute"]=420;
    s.testNow+=((1340-BeastSleep.minuteAt(s.now())+1440)%1440)*60;s.tick();s.setLighting(2);
    Test.assert(s.isSleeping());Test.assert(s.wakeUp());Test.assert(s.isNight());Test.assert(!s.isSleeping());
    Test.assertEqual(s.grump(),1);Test.assert(s.isDark());Test.assertEqual(s.lightingMode(),2);
    var at=s.now();var end=s.number("awakeUntil");Test.assertEqual(BeastSleep.minuteAt(end),420);
    var reload=new TekuTekuBeastState();reload.store=s.store;reload.skipWatch=true;reload.testNow=at+60;reload.start();
    Test.assert(!reload.isSleeping());Test.assertEqual(reload.grump(),1);
    Test.assert(!BeastSleep.sleeping(s.store.read("glance.v1"),at));Test.assert(BeastSleep.previewMood(s.store.read("glance.v1"),at).equals("GRUMPY"));
    reload.testNow=at-1;Test.assert(reload.isSleeping());reload.testNow=at;
    reload.data["awakeZone"]+=3600;Test.assert(reload.isSleeping());reload.data["awakeZone"]-=3600;
    reload.testNow=end;Test.assert(!reload.isSleeping());Test.assertEqual(reload.grump(),0);
    reload.testNow=end+15*3600;Test.assert(reload.isSleeping());Test.assertEqual(reload.number("bedMinute"),1320);
    var watch=TestSupport.fixture();watch.data["nextBed"]=watch.now()+18*3600;watch.data["nextWake"]=watch.now()+2*3600;
    watch.data["scheduleAt"]=watch.now();Test.assert(watch.wakeUp());Test.assertEqual(watch.number("awakeUntil"),watch.number("nextWake"));
    return true;
}
(:test)
function wakeRestRewardAndEnergyTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=2;s.data["energy"]=10;s.rest();
    var energy=s.number("energy");var growth=s.number("careGrowth");var personality=s.store.copy(s.data["personality"]);
    for(var i=0;i<10;i++){Test.assert(s.wakeUp());Test.assert(!s.wakeUp());s.rest();}
    Test.assertEqual(s.number("energy"),energy);Test.assertEqual(s.number("careGrowth"),growth);
    Test.assert(TestSupport.same(personality,s.data["personality"]));Test.assertEqual(s.xp(),0l);Test.assertEqual(s.number("rested"),1);
    var began=s.now();s.testNow+=2700;Test.assert(s.wakeUp());
    Test.assert(BeastSleep.sleeping(s.data,began+1800));Test.assert(!BeastSleep.sleeping(s.data,began+3000));
    s.testNow=began+3600;var forecast=BeastSleep.forecastEnergy(s.data,s.now());s.tick();Test.assertEqual(s.number("energy"),forecast);
    s.testNow=began-1;Test.assert(!s.isSleeping()); // no multi-day nap after rollback
    return true;
}
(:test)
function sleepingGameCheckpointTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=2;s.data["adventure"]=2;
    var game=new BeastGameView(s,2);game.begin();var id=game.session["id"];s.rest();var saved=s.store.copy(s.data);
    game.refresh();Test.assertEqual(game.phase,3);Test.assert(game.result.equals("Beast is asleep."));
    Test.assertEqual(s.data["sessions"][2]["id"],id);Test.assertEqual(s.number("adventure"),1);
    Test.assert(s.completeSession(s.data["sessions"][2],true).equals("Beast is asleep."));Test.assert(TestSupport.same(saved,s.data));
    Test.assert(s.wakeUp());game.refresh();Test.assertEqual(game.phase,0);game.begin();Test.assertEqual(game.session["id"],id);
    Test.assertEqual(s.number("adventure"),1);s.completeSession(game.session,true);var discoveries=s.number("encounters");
    s.completeSession(game.session,true);Test.assertEqual(s.number("encounters"),discoveries);Test.assertEqual(discoveries,1);return true;
}
(:test)
function wakeMigrationAndDevIsolationTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=2;s.observe(s.today(),4250);s.rest();s.commit();
    var old=s.store.copy(s.store.read("v4"));var fields=["awakeAt","awakeUntil","awakeZone","grumpAt","grumpLevel"];
    for(var i=0;i<fields.size();i++){old.remove(fields[i]);}s.store.write("v4",old);
    var reload=new TekuTekuBeastState();reload.store=s.store;reload.skipWatch=true;reload.testNow=s.now()+1200;reload.start();
    Test.assert(reload.isSleeping());Test.assertEqual(reload.number("awakeAt"),0l);Test.assertEqual(reload.xp(),4250l);
    var dev=reload.enableDev();var real=reload.store.copy(reload.store.read("v4"));Test.assert(dev.wakeUp());Test.assertEqual(dev.grump(),2);
    Test.assert(TestSupport.same(real,reload.store.read("v4")));Test.assert(reload.isSleeping());
    Test.assert(reload.wakeUp());var view=new TekuTekuBeastView();view.beast=reload;
    Test.assert(view.visualState().equals("grumpy"));Test.assertEqual(view.desiredPeriod(),1000);
    var joy=reload.happiness();reload.testNow+=150;Test.assertEqual(reload.happiness(),joy+1);
    reload.testNow+=150;Test.assertEqual(reload.grump(),0);return true;
}

(:test)
function lightingModesPersistenceTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=1;s.data["bedMinute"]=1320;s.data["wakeMinute"]=420;
    s.testNow+=((1320-BeastSleep.minuteAt(s.now())+1440)%1440)*60;s.data["lastCare"]=s.now();
    s.commit();var original=s.store.copy(s.data);var xp=s.xp();
    Test.assertEqual(s.lightingMode(),0);Test.assert(s.isDark());Test.assert(s.isSleeping());
    s.setLighting(1);Test.assert(!s.isDark());Test.assert(s.isSleeping());Test.assertEqual(s.lightingMode(),1);
    Test.assertEqual(s.lightingMinutes(),60);var until=s.number("lightsUntil");
    var reload=new TekuTekuBeastState();reload.store=s.store;reload.skipWatch=true;reload.testNow=s.testNow+1800;reload.start();
    Test.assertEqual(reload.lightingMode(),1);Test.assertEqual(reload.lightingMinutes(),30);Test.assert(!reload.isDark());
    reload.testNow=until-1;Test.assertEqual(reload.lightingMinutes(),1);Test.assert(!reload.isDark());
    var writes=s.store.writes;reload.testNow=until;
    for(var i=0;i<100;i++){Test.assertEqual(reload.lightingMode(),0);Test.assert(reload.isDark());}
    Test.assertEqual(s.store.writes,writes);Test.assertEqual(reload.xp(),xp);
    reload.setLighting(2);Test.assert(reload.isDark());reload.setLighting(0);Test.assert(reload.isDark());
    Test.assertEqual(reload.number("lightsUntil"),0l);Test.assertEqual(reload.data["items"].size(),original["items"].size());
    // AUTO retains the existing bedtime-dimming preference, including disabled.
    reload.data["autoLights"]=0;Test.assert(!reload.isDark());Test.assert(reload.isSleeping());
    reload.setLighting(2);Test.assert(reload.isDark());reload.testNow-=7200;Test.assertEqual(reload.lightingMode(),0);
    Test.assert(!reload.isDark());return true;
}
(:test)
function lightingSkyAndMenusTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=2;s.commit();
    var world=new BeastWorld(s);world.prefs["locationMode"]=3;var real=s.realNow();
    real+=((720-BeastSleep.minuteAt(real)+1440)%1440)*60;
    var sample=s.store.copy(world.update(real,false));var calculations=world.computations;
    Test.assertEqual(sample[0],1);
    var v=new TekuTekuBeastView();v.beast=s;v.openMenu("Actions");
    Test.assert(v.rows[7].equals("Lights: AUTO"));v.selection=7;v.selectAction();Test.assert(v.menu.equals("Lighting"));
    v.selection=2;v.selectAction();Test.assertEqual(s.lightingMode(),2);Test.assert(s.isDark());Test.assert(!s.isSleeping());
    Test.assert(TestSupport.same(sample,world.update(real,false)));Test.assertEqual(world.computations,calculations);
    var night=s.store.copy(world.update(real+43200,false));Test.assertEqual(night[0],3);
    s.setLighting(1);Test.assert(TestSupport.same(night,world.update(real+43200,false)));s.setLighting(2);
    v.openMenu("Lighting");Test.assert(v.rows[2].equals("* OFF: 1 hour"));Test.assert(v.rows[3].equals("Applied: OFF"));
    var key=v.visualKey();s.testNow+=3600;v.refresh();Test.assertEqual(s.lightingMode(),0);
    Test.assert(v.rows[0].equals("* AUTO"));Test.assert(v.rows[3].equals("Applied: ON"));Test.assert(!key.equals(v.visualKey()));
    Test.assert(v.refresher==null);Test.assert(v.back());Test.assert(v.menu.equals("Actions"));
    var d=s.enableDev();var saved=s.store.copy(s.store.read("v4"));d.setLighting(2);d.jump(1800);
    Test.assertEqual(d.lightingMode(),2);Test.assert(TestSupport.same(saved,s.store.read("v4")));
    return true;
}

(:test)
function gameGoldenVectorsTest(logger){
    var rows=RuleVectors.games();
    for(var i=0;i<rows.size();i++){
        var row=rows[i];Test.assertEqual(BeastGameRules.nextSeed(row["seed"]),row["nextSeed"]);
        Test.assertEqual(BeastGameRules.treasureItem(row["seed"],row["risk"],row["finds"],row["route"],row["mask"]),row["item"]);
    }
    Test.assertEqual(BeastGameRules.trailSeed(1,2,1,1),447);
    var normal=[16,12,9];var easyPeriods=[24,20,16];var jump=[7,6,5];
    for(var round=0;round<3;round++){
        Test.assertEqual(BeastGameRules.period(false,round),normal[round]);Test.assertEqual(BeastGameRules.period(true,round),easyPeriods[round]);
        Test.assertEqual(BeastGameRules.jumpDuration(false,round),jump[round]);Test.assertEqual(BeastGameRules.jumpDuration(true,round),7);
    }
    var sequence=[0,0,2];var copy=new BeastStore().copy(sequence);
    for(var easy=0;easy<2;easy++){
        var on=BeastGameRules.tempo(easy==1);var cycle=on+BeastGameRules.cueGap();
        for(var cue=0;cue<sequence.size();cue++){
            Test.assertEqual(BeastGameRules.displayedMove(sequence,1,cue*cycle,easy==1),sequence[cue]);
            Test.assertEqual(BeastGameRules.displayedMove(sequence,1,cue*cycle+on-1,easy==1),sequence[cue]);
            Test.assertEqual(BeastGameRules.displayedMove(sequence,1,cue*cycle+on,easy==1),-1);
        }
    }
    Test.assertEqual(BeastGameRules.displayedMove([],1,0,false),-1);
    Test.assertEqual(BeastGameRules.displayedMove(sequence,2,0,false),-1);
    Test.assert(TestSupport.same(sequence,copy));return true;
}

(:test)
function activityGoldenVectorsTest(logger){
    var rows=RuleVectors.activity();var fields=["xp","snacks","snackRemainder","activityMilestone","adventure","activityBonus"];
    for(var i=0;i<rows.size();i++){
        var row=rows[i];logger.debug(row["name"]);var s=TestSupport.fixture();var keys=row["data"].keys();
        for(var k=0;k<keys.size();k++){s.data[keys[k]]=row["data"][keys[k]];}
        var day=s.number("day");var writes=s.store.writes;var ruleData=s.store.copy(s.data);
        for(var j=0;j<row["samples"].size();j++){
            var sample=row["samples"][j];var steps=sample["steps"];var minutes=sample["minutes"];var pushes=sample["pushes"];
            if(steps!=null){s.observe(day,steps);BeastActivityRules.observe(ruleData,day,steps);}
            s.activityRewards(day,steps,minutes,pushes);BeastActivityRules.rewards(ruleData,day,steps,minutes,pushes);
            for(var k=0;k<fields.size();k++){Test.assert(s.data[fields[k]]==sample["expected"][k]);}
            Test.assert(TestSupport.same(ruleData,s.data));Test.assertEqual(s.store.writes,writes);
        }
        var before=s.store.copy(s.data);BeastActivityRules.observe(s.data,day-1,90000);
        BeastActivityRules.observe(s.data,day,-1);BeastActivityRules.rewards(s.data,day-1,90000,99,9999);
        Test.assert(TestSupport.same(before,s.data));
    }
    Test.assert(GarminActivity.steps(null)==null);Test.assert(GarminActivity.minutes(null)==null);
    Test.assert(GarminActivity.pushes(null)==null);return true;
}

(:test)
function progressionGoldenVectorsTest(logger){
    var vectors=RuleVectors.progression();
    for(var i=0;i<vectors.size();i++){
        var row=vectors[i];var s=TestSupport.fixture();var keys=row["data"].keys();
        for(var k=0;k<keys.size();k++){s.data[keys[k]]=row["data"][keys[k]];}
        s.testNow+=row["ageSeconds"];var before=s.store.copy(s.data);var expected=row["expected"];
        logger.debug(row["name"]);
        Test.assert(BeastProgression.stage(s.data,s.now())==expected["stage"]);
        Test.assert(s.stage()==expected["stage"]);
        Test.assert(BeastProgression.hatchDurationHours(s.data)==expected["hatchHours"]);
        Test.assert(s.growth()==expected["growth"]);
        Test.assert(TestSupport.same(before,s.data));
    }
    return true;
}
(:test)
function progressionPurityAndAdvanceTest(logger){
    var s=TestSupport.fixture();var before=s.store.copy(s.data);
    Test.assertEqual(BeastProgression.chooseFamily(s.data),1);
    Test.assert(TestSupport.same(before,s.data));
    for(var family=0;family<4;family++){
        s.data["personality"]=[0,0,0,0];s.data["personality"][family]=2;
        Test.assertEqual(BeastProgression.chooseFamily(s.data),family+1);
    }
    var xp=s.xp();var storeWrites=s.store.writes;var start=s.now();
    BeastProgression.advance(s.data,start+1);BeastProgression.advance(s.data,start+86400);
    Test.assert(s.number("baseGrowth")==12000);Test.assert(s.number("growthRemainder")==0);
    Test.assert(s.xp()==xp);Test.assertEqual(s.store.writes,storeWrites);
    before=s.store.copy(s.data);BeastProgression.advance(s.data,start+86399);
    Test.assert(TestSupport.same(before,s.data));
    s.data["stageFloor"]=5;s.data["baseGrowth"]=325000l;
    Test.assert(s.mastery()==2);Test.assert(s.progress()==0);
    return true;
}

(:test)
function compactGlanceAndDeferredCatchupTest(logger){
    var s=TestSupport.fixture();s.observe(s.today(),3000);s.data["friendship"]=71;
    s.data["items"][7]=9;s.beginSession(1);s.commit();
    var cache=s.store.read("glance.v1");Test.assert(cache!=null);
    Test.assert(!cache.hasKey("days"));Test.assert(!cache.hasKey("sessions"));
    Test.assertEqual(cache["friendship"],71);
    var xp=s.xp();var serial=s.number("gameSerial");s.testNow+=26*86400;
    s.syncHistory();Test.assertEqual(s.xp(),xp);Test.assertEqual(s.stage(),5);
    Test.assertEqual(s.number("evolutionPending"),1);Test.assertEqual(s.data["items"][7],9);
    Test.assertEqual(s.number("gameSerial"),serial);s.data["evolutionPending"]=0;s.commit();
    var reload=new TekuTekuBeastState();reload.store=s.store;reload.skipWatch=true;reload.testNow=s.testNow;
    reload.syncHistory();Test.assertEqual(reload.number("evolutionPending"),0);
    Test.assertEqual(reload.friendship(),71);Test.assertEqual(reload.xp(),xp);
    var before=reload.store.writes;reload.commit();Test.assertEqual(reload.store.writes,before);
    return true;
}

(:test)
function solarSeasonsTest(logger){
    var june=BeastSky.midnight(2026,6,21);var december=BeastSky.midnight(2026,12,21);
    // Broad 10-minute envelopes for NOAA approximation vs published civil
    // sunrise tables; never assert second-level astronomical precision.
    var london=BeastSky.calculate(june,51.5074,-0.1278);
    Test.assert(BeastSky.abs(london[0]-(june+3*3600+43*60))<600);
    Test.assert(BeastSky.abs(london[1]-(june+20*3600+21*60))<600);
    var winter=BeastSky.calculate(december,51.5074,-0.1278);
    Test.assert(BeastSky.abs(winter[0]-(december+8*3600+4*60))<600);
    Test.assert(BeastSky.abs(winter[1]-(december+15*3600+54*60))<600);
    var brisbane=BeastSky.calculate(december,-27.47,153.03);
    Test.assert(BeastSky.abs(brisbane[0]-(december-5*3600-11*60))<600);
    Test.assert(BeastSky.abs(brisbane[1]-(december+8*3600+42*60))<600);
    var north=BeastSky.calculate(june,78.2,15.6);Test.assertEqual(north[2],1);
    Test.assertEqual(BeastSky.calculate(december,78.2,15.6)[2],-1);
    Test.assertEqual(BeastSky.calculate(june,-89.99,0.0)[2],-1);
    Test.assertEqual(BeastSky.calculate(december,-89.99,0.0)[2],1);
    Test.assert(BeastSky.valid(0,0));Test.assert(!BeastSky.valid(91,0));Test.assert(!BeastSky.valid(0,181));
    var leap=BeastSky.calculate(BeastSky.midnight(2028,2,29),0.0,179.9);Test.assert(leap[1]>leap[0]);return true;
}
(:test)
function v051TimeZoneSolarBracketTest(logger){
    var date=BeastSky.midnight(2026,1,1);var days=[];
    for(var i=-1;i<=1;i++){days.add(BeastSky.calculate(date+i*86400,0.0,179.9));}
    var now=date+20*3600;var index=BeastSky.chooseDay(now,days);Test.assertEqual(index,2);
    Test.assert(BeastSky.sample(now,days[index],days[index-1],[0l,0l,1])[2]);
    days=[];for(var i=-1;i<=1;i++){days.add(BeastSky.calculate(date+i*86400,0.0,0.0));}
    now=days[1][1]+300;index=BeastSky.chooseDay(now,days);Test.assertEqual(index,2);
    Test.assertEqual(BeastSky.sample(now,days[index],days[index-1],[0l,0l,1])[0],2);
    now=days[2][0]-300;Test.assertEqual(BeastSky.sample(now,days[2],days[1],[0l,0l,1])[0],0);
    days=[];for(var i=-1;i<=1;i++){days.add(BeastSky.calculate(date+i*86400,0.0,-179.9));}
    now=date-86400+12*3600;index=BeastSky.chooseDay(now,days);Test.assertEqual(index,0);
    Test.assert(!BeastSky.sample(now,days[0],[0l,0l,-1],days[1])[2]);return true;
}
(:test)
function skyCycleAndSleepTest(logger){
    var s=TestSupport.fixture();var before=s.store.copy(s.data);var now=s.realNow();
    var w=new BeastWorld(s);w.update(now,false);Test.assertEqual(w.source,"FIXED 06-18");
    var count=w.computations;w.update(now+1,false);Test.assertEqual(w.computations,count);
    Test.assert(w.accept(-27.47,153.03,now));Test.assert(!w.accept(95,0,now));
    w.update(now,false);Test.assertEqual(w.source,"SAVED LOCATION");
    var today=w.days[1];var dawn=BeastSky.sample(today[0],today,w.days[0],w.days[2]);Test.assertEqual(dawn[0],0);Test.assert(dawn[2]);
    var noon=BeastSky.sample((today[0]+today[1])/2,today,w.days[0],w.days[2]);Test.assertEqual(noon[0],1);Test.assert(BeastSky.abs(noon[1]-0.5)<0.001);
    Test.assertEqual(BeastSky.sample(today[1],today,w.days[0],w.days[2])[0],2);
    var night=BeastSky.sample(today[1]+3600,today,w.days[0],w.days[2]);Test.assertEqual(night[0],3);Test.assert(!night[2]);
    // Changing astronomical phase cannot modify any sleep flag or pet ledger.
    Test.assertEqual(s.number("sleepMode"),before["sleepMode"]);Test.assertEqual(s.number("sleepUntil"),before["sleepUntil"]);
    Test.assertEqual(s.xp(),before["xp"]);Test.assertEqual(s.number("baseGrowth"),before["baseGrowth"]);
    var reopened=new BeastWorld(s);reopened.update(now,false);Test.assertEqual(reopened.days[1][0],today[0]);
    var chosen=w.choose(1,0);Test.assertEqual(w.choose(4,5),chosen);w.setTheme(4);Test.assertEqual(w.choose(1,0),3);
    var d=s.enableDev();var dw=new BeastWorld(d);dw.setTheme(2);dw.accept(40,-74,now);dw.preview=3;dw.update(now,false);
    Test.assertEqual(dw.sample[0],3);var real=new BeastWorld(s);Test.assertEqual(real.prefs["environment"],4);Test.assertEqual(real.prefs["lat"],-27.47);
    Test.assertEqual(s.store.read("v4")["xp"],before["xp"]);return true;
}

(:test)
module TestSupport {
    function same(a,b){
        if(a instanceof Lang.Dictionary){if(!(b instanceof Lang.Dictionary) || a.size()!=b.size()){return false;}var keys=a.keys();for(var i=0;i<keys.size();i++){if(!b.hasKey(keys[i]) || !same(a[keys[i]],b[keys[i]])){return false;}}return true;}
        if(a instanceof Lang.Array){if(!(b instanceof Lang.Array) || a.size()!=b.size()){return false;}for(var i=0;i<a.size();i++){if(!same(a[i],b[i])){return false;}}return true;}
        return a==b;
    }
    function fixture(){
        var s=new TekuTekuBeastState();s.store.memory={};s.skipWatch=true;s.testNow=1792108800l;s.start();return s;
    }
}
(:test)
function v05WorldSaveAndDateTest(logger){
    var s=TestSupport.fixture();s.observe(s.today(),123456);s.data["items"]=[2,3,4,5,6,7,8,9];s.data["collection"]=15;s.data["rareCollection"]=3;
    s.data["friendship"]=71;s.data["snacks"]=12;s.commit();var before=s.store.copy(s.store.read("v4"));
    var w=new BeastWorld(s);w.setTheme(3);w.accept(51.5,-0.1,s.realNow());w.update(s.realNow(),false);
    w.update(s.realNow()+86400,false);Test.assertEqual(w.computations,2);
    Test.assert(TestSupport.same(before,s.store.read("v4")));
    var reload=new TekuTekuBeastState();reload.store=s.store;reload.skipWatch=true;reload.testNow=s.testNow;reload.start();
    Test.assert(TestSupport.same(before,reload.data));
    var confirmed=w.prefs["manualLat"];w.draftLat=-40.0;w.draftLon=-74.0;w.setTheme(2);
    Test.assertEqual(s.store.read("world.v1")["manualLat"],confirmed);
    var unconfirmed=new BeastWorld(s);Test.assertEqual(unconfirmed.draftLat,confirmed);
    Test.assert(w.confirmManual());Test.assertEqual(s.store.read("world.v1")["manualLat"],-40.0);
    Test.assert(TestSupport.same(before,s.store.read("v4")));
    var d=s.enableDev();var devBefore=s.store.copy(s.store.read("v4"));var dw=new BeastWorld(d);var prefs=s.store.copy(s.store.read("world.v1"));
    dw.prefs["locationMode"]=2;dw.prefs["manualSet"]=1;dw.prefs["manualLat"]=-40.0;dw.update(s.realNow(),false);dw.save();
    Test.assert(TestSupport.same(prefs,s.store.read("world.v1")));
    // Enabling DEV reconciles real elapsed care/growth first, as in v0.5.
    // Only changes made AFTER that boundary must leave this snapshot identical.
    Test.assert(TestSupport.same(devBefore,s.store.read("v4")));
    s.data["sleepMode"]=2;s.data["sleepUntil"]=0l;var asleep=s.isSleeping();
    w.update(s.realNow()+43200,false);Test.assertEqual(s.isSleeping(),asleep);
    return true;
}
(:test)
function v051MemoryAndStarTimingTest(logger){
    var s=TestSupport.fixture();var m=new BeastGameView(s,1);m.begin();m.sequence=[0,0,2];
    m.elapsed=m.tempo()-1;Test.assertEqual(m.displayedMove(),0);m.elapsed=m.tempo();Test.assertEqual(m.displayedMove(),-1);
    m.elapsed=m.tempo()+m.cueGap();Test.assertEqual(m.displayedMove(),0);
    m.elapsed=2*(m.tempo()+m.cueGap())-1;Test.assertEqual(m.displayedMove(),-1);
    m.checkpoint();var old=s.store.copy(m.session);old.remove("timingV051");old["elapsed"]=6;
    var resumed=new BeastGameView(s,1);resumed.restore(old);Test.assertEqual(resumed.elapsed,7);Test.assertEqual(resumed.sequence[0],0);
    var star=new BeastGameView(s,0);Test.assertEqual(star.period(),16);star.round=1;Test.assertEqual(star.period(),12);
    star.round=2;Test.assertEqual(star.period(),9);Test.assertEqual(star.jumpDuration(),5);
    star.begin();star.elapsed=10;star.hits=2;star.checkpoint();var prior=s.store.copy(star.session);prior.remove("timingV051");
    var again=new BeastGameView(s,0);again.restore(prior);Test.assertEqual(again.elapsed,8);Test.assertEqual(again.hits,2);Test.assertEqual(again.session["id"],prior["id"]);
    s.data["easy"]=1;star.round=0;Test.assertEqual(star.period(),24);star.round=1;Test.assertEqual(star.period(),20);star.round=2;Test.assertEqual(star.period(),16);
    Test.assertEqual(m.tempo(),8);Test.assertEqual(m.cueGap(),1);Test.assertEqual(s.xp(),0l);return true;
}
(:test)
function v051DirtySaveAndDuplicateStepTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=2;s.observe(s.today(),3000);s.activityRewards(s.today(),3000,null,null);s.commit();
    s.store.writes=0;s.store.skipped=0;
    for(var i=0;i<100;i++){s.commit();Test.assert(s.stepNoop(3000,null,null));}
    Test.assertEqual(s.store.writes,0);Test.assert(s.store.skipped>=100);Test.assertEqual(s.xp(),3000l);
    Test.assert(!s.stepNoop(3001,null,null));s.data["minutesBase"]=0;Test.assert(!s.stepNoop(3000,20,null));
    s.data["pushBase"]=0;Test.assert(!s.stepNoop(3000,null,1000));
    // One canonical write plus its tiny read-only Glance cache, then no-op.
    s.data["friendship"]++;s.commit();Test.assertEqual(s.store.writes,2);s.commit();Test.assertEqual(s.store.writes,2);
    s.data["poopDue"]=s.now();Test.assert(!s.stepNoop(3000,null,null));s.data["poopDue"]=0l;
    s.testNow+=61;Test.assert(!s.stepNoop(3000,null,null));s.syncToday();
    var after=s.xp();s.observe(s.today(),3001);s.commit();Test.assertEqual(s.xp(),after+1);
    logger.debug("BATTERY_AUDIT: 100 identical commits -> 0 writes; duplicate-step preflight=100/100; new step persisted");return true;
}
(:test)
function v051RoamingBoundsTest(logger){
    var v=new TekuTekuBeastView();v.beast=TestSupport.fixture();var profiles=[[240,96],[260,96],[280,96],[390,144],[416,144],[454,192]];
    for(var p=0;p<profiles.size();p++){
        var width=profiles[p][0];var size=profiles[p][1];var minX=10000;var maxX=0;var minY=10000;var maxY=0;var radius=width/2-8;
        for(var i=0;i<v.roamX.size();i++){
            v.positionCreature(width,width,size,width*(0.5+v.roamX[i]),width*v.roamY[i]);var box=v.petBounds;
            minX=v.beast.min(minX,box[0]);maxX=v.beast.max(maxX,box[0]);minY=v.beast.min(minY,box[1]);maxY=v.beast.max(maxY,box[1]);
            for(var corner=0;corner<4;corner++){var x=box[0]+(corner%2==0?0:box[2])-width/2;var y=box[1]+(corner<2?0:box[3])-width/2;Test.assert(x*x+y*y<=radius*radius);}
            Test.assert(box[1]>=width*0.18-1);Test.assert(box[1]+box[3]<=width*0.745);
        }
        Test.assert(maxX-minX>=width*0.30);Test.assert(maxY-minY>=width*0.14);
        logger.debug("ROAM_AUDIT: "+width+"px canvas="+size+" horizontal="+(maxX-minX)+" vertical="+(maxY-minY));
    }return true;
}
(:test)
function v051RedrawAndTimerAuditTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=2;s.data["motion"]=0;var v=new TekuTekuBeastView();v.beast=s;
    Test.assertEqual(v.desiredPeriod(),5000);v.timerPeriod=5000;
    for(var i=0;i<40;i++){v.refresh();}Test.assertEqual(v.redrawRequests,1);Test.assert(v.refresher==null);
    s.data["motion"]=2;s.data["energy"]=0;Test.assertEqual(v.desiredPeriod(),5000);s.data["energy"]=80;
    var m=new BeastGameView(s,1);m.begin();m.sequence=[0,0,2];m.timerPeriod=250;
    for(var i=0;i<21;i++){m.refresh();}Test.assertEqual(m.phase,2);Test.assert(m.gameRedraws<=8);
    logger.debug("REDRAW_AUDIT: 40 unchanged Pet callbacks -> "+v.redrawRequests+" redraw; 21 memory cue ticks -> "+m.gameRedraws+" redraws");return true;
}
(:test)
function migrationTest(logger){
    var s=new TekuTekuBeastState();s.store.memory={"birth"=>20261015,"birthEpoch"=>1792022400l,"birthBaseline"=>100,
        "xp"=>5974,"snacks"=>2,"friendship"=>6,"patDay"=>20261015,"pats"=>3,"day15"=>20261015,"count15"=>5974};
    s.skipWatch=true;s.testNow=1792108800l;s.start();
    Test.assertEqual(s.xp(),5974l);Test.assertEqual(s.stage(),1);Test.assertEqual(s.friendship(),6);Test.assertEqual(s.snacks(),2);
    Test.assertEqual(s.store.read("xp"),5974);s.commit();var again=new TekuTekuBeastState();again.store=s.store;again.skipWatch=true;again.testNow=s.testNow;again.start();
    Test.assertEqual(again.xp(),5974l);Test.assertEqual(again.stage(),1);return true;
}
(:test)
function devIsolationTest(logger){
    var s=TestSupport.fixture();s.observe(s.today(),3000);s.commit();var d=s.enableDev();
    d.jump(604800);d.devSet("forcedStage",5);d.devSet("friendship",100);d.devSet("snacks",12);d.pat();d.commit();
    Test.assertEqual(s.store.read("v4")["xp"],3000l);Test.assertEqual(s.store.read("v4")["friendship"],0);
    d.observe(s.today(),999999);Test.assertEqual(d.xp(),3000l);
    var restored=new TekuTekuBeastState();restored.store=s.store;restored.testNow=s.testNow;restored.skipWatch=true;restored.start();
    restored.observe(s.today(),4500);restored.commit();Test.assertEqual(restored.xp(),4500l);Test.assertEqual(restored.stage(),0);return true;
}
(:test)
function passiveGrowthTest(logger){
    var s=TestSupport.fixture();s.testNow+=7*86400;s.tick();Test.assertEqual(s.growth(),84000l);Test.assertEqual(s.stage(),3);
    s.testNow+=18*86400;s.tick();Test.assertEqual(s.growth(),300000l);Test.assertEqual(s.stage(),5);Test.assertEqual(s.xp(),0l);
    s.testNow+=75*86400;s.tick();Test.assertEqual(s.growth(),1200000l);Test.assert(s.mastery()>1);
    var g=s.growth();s.tick();Test.assertEqual(s.growth(),g);s.testNow-=86400;s.tick();Test.assertEqual(s.growth(),g);return true;
}
(:test)
function hatchTest(logger){
    var s=TestSupport.fixture();s.observe(s.today(),20000);s.testNow+=7*3600;s.tick();Test.assertEqual(s.stage(),0);
    s.testNow+=3600;s.tick();Test.assertEqual(s.stage(),1);
    var z=TestSupport.fixture();z.testNow+=23*3600;z.tick();Test.assertEqual(z.stage(),0);z.testNow+=3600;z.tick();Test.assertEqual(z.stage(),1);return true;
}
(:test)
function careAndRewardTest(logger){
    var s=TestSupport.fixture();Test.assert(s.feedFood(true));Test.assertEqual(s.number("meals"),1);Test.assertEqual(s.xp(),0l);
    s.testNow+=4*3600;s.tick();Test.assertEqual(s.number("poop"),1);Test.assert(s.clean());Test.assert(!s.clean());
    s.testNow+=86400;s.tick();Test.assertEqual(s.number("meals"),2);s.feedFood(true);var meals=s.number("meals");
    s.testNow-=86400;s.tick();Test.assertEqual(s.number("meals"),meals);
    for(var i=0;i<8;i++){s.gameReward(true,i%2);}Test.assertEqual(s.number("games"),3);Test.assertEqual(s.xp(),0l);return true;
}
(:test)
function stepsAndAlternativesTest(logger){
    var s=TestSupport.fixture();var day=s.today();s.observe(day,5000);s.observe(day,5000);s.observe(day,4000);Test.assertEqual(s.xp(),5000l);Test.assertEqual(s.snacks(),2);
    s.activityRewards(day,5000,0,0);s.activityRewards(day,5000,20,1000);s.activityRewards(day,5000,20,1000);Test.assertEqual(s.number("adventure"),2);
    var z=TestSupport.fixture();z.careReward(300,3);Test.assertEqual(z.number("adventure"),3);
    for(var i=0;i<8;i++){z.data["adventure"]++;z.explore(0);}for(var i=0;i<8;i++){Test.assert(z.data["items"][i]>0);}Test.assertEqual(z.xp(),0l);return true;
}
(:test)
function familiesTest(logger){
    for(var f=0;f<4;f++){var s=TestSupport.fixture();s.data["personality"][f]=20;s.testNow+=25*86400;s.tick();Test.assertEqual(s.family(),f+1);
        s.data["friendship"]=70;Test.assert(s.rareEvolve());Test.assertEqual(s.number("rare"),1);Test.assertEqual(s.xp(),0l);}
    return true;
}
(:test)
function navigationAndDevTest(logger){
    var v=new TekuTekuBeastView();v.beast=TestSupport.fixture();v.selectAction();
    Test.assertEqual(v.rows.size(),8);v.selection=6;v.selectAction();Test.assert(v.menu.equals("Settings"));
    v.selectAction();v.selectAction();Test.assert(v.beast.dev);Test.assert(v.menu.equals("Dev Tools"));
    v.selection=0;v.selectAction();v.selection=3;v.selectAction();Test.assertEqual(v.beast.speed,100);
    v.selection=1;v.selectAction();v.selection=2;v.selectAction();Test.assertEqual(v.beast.ageDays(),7);
    v.openMenu("Settings");v.selectAction();v.selectAction();Test.assert(!v.beast.dev);Test.assertEqual(v.beast.ageDays(),0);
    Test.assertEqual(v.beast.xp(),0l);return true;
}
(:test)
function miniGamesTest(logger){
    var s=TestSupport.fixture();s.data["haptics"]=0;
    var star=new BeastGameView(s,0);Test.assertEqual(star.desiredGamePeriod(),1000);star.selectAction();Test.assertEqual(star.desiredGamePeriod(),250);
    Test.assertEqual(star.resultTouchChoice(220),0);Test.assertEqual(star.resultTouchChoice(255),1);
    for(var attempt=0;attempt<15;attempt++){
        star.lane=star.target;star.elapsed=(star.period()/2).toNumber()-1;star.selectAction();star.refresh();
        Test.assert(star.caught);
        while(star.phase==1 && star.attempts==attempt){star.refresh();}
    }
    Test.assertEqual(star.phase,3);Test.assertEqual(star.hits,15);Test.assertEqual(s.number("games"),1);
    Test.assertEqual(star.desiredGamePeriod(),1000);
    var scout=new BeastGameView(s,2);scout.result="SCOUT COMPLETE";Test.assert(scout.resultDetail().equals("SCOUT: NO LOOT"));
    scout.result="FOUND BERRY";Test.assert(scout.resultDetail().equals("IN YOUR COLLECTION"));
    Test.assert(scout.trailChoice().equals("> HELP"));scout.node=1;Test.assert(scout.trailChoice().equals("> CROSS"));
    scout.choice=1;Test.assert(scout.trailChoice().equals("> DETOUR"));scout.node=2;Test.assert(scout.trailChoice().equals("> PUSH OPEN"));
    var memory=new BeastGameView(s,1);memory.selectAction();
    for(var round=0;round<3;round++){
        memory.phase=2;
        while(memory.phase==2){memory.memoryInput(memory.sequence[memory.cursor]);}
        memory.continueMemory();
    }
    Test.assertEqual(memory.phase,3);Test.assertEqual(memory.hits,3);Test.assertEqual(s.number("games"),2);
    var scan=new BeastGameView(s,1);scan.scanning=true;scan.selectAction();
    for(var round=0;round<3;round++){
        scan.phase=2;
        while(scan.phase==2){scan.tick=scan.sequence[scan.cursor]*6;scan.selectAction();}
        scan.continueMemory();
    }
    Test.assertEqual(scan.phase,3);Test.assertEqual(s.number("games"),3);
    var timeout=new BeastGameView(s,0);timeout.selectAction();
    for(var i=0;i<300;i++){timeout.refresh();}
    Test.assertEqual(timeout.phase,3);Test.assertEqual(s.number("games"),3);Test.assertEqual(s.xp(),0l);
    timeout.refresh();Test.assertEqual(s.number("games"),3);return true;
}
(:test)
function activeBalanceAndArchiveTest(logger){
    var s=TestSupport.fixture();
    for(var i=0;i<21;i++){s.testNow+=86400;s.tick();s.observe(s.today(),10000);}
    s.tick();Test.assertEqual(s.stage(),5);Test.assertEqual(s.xp(),210000l);
    var steps=s.xp();Test.assert(s.newEgg());Test.assertEqual(s.stage(),0);Test.assertEqual(s.xp(),steps);Test.assertEqual(s.growth(),0l);
    Test.assert(s.store.read("v4.archive")!=null);Test.assert(s.number("collection")>0);
    s.testNow+=86400;s.tick();Test.assertEqual(s.stage(),1);return true;
}
(:test)
function devInventoryAndItemsTest(logger){
    var s=TestSupport.fixture();var d=s.enableDev();d.data["items"][5]=1;Test.assert(d.useItem(5));Test.assertEqual(d.number("equipped"),5);
    d.newEgg();d.commit();Test.assertEqual(s.store.read("v4")["items"][5],0);Test.assert(s.store.read("v4.dev.archive")==null);return true;
}
(:test)
function earlySaveAgeTest(logger){
    var s=new TekuTekuBeastState();s.testNow=1792108800l;s.skipWatch=true;
    var birthday=s.dateKey(new Toybox.Time.Moment((s.testNow-30*86400).toNumber()));
    s.store.memory={"birth"=>birthday,"xp"=>300000,"family"=>2,"friendship"=>75,"snacks"=>4};s.start();
    Test.assertEqual(s.ageDays(),30);Test.assertEqual(s.stage(),5);Test.assertEqual(s.family(),2);
    Test.assertEqual(s.friendship(),75);Test.assertEqual(s.xp(),300000l);return true;
}
(:test)
function freshEggScenarioTest(logger){
    var s=TestSupport.fixture();s.testNow+=86400;s.tick();s.observe(s.today(),3000);s.commit();
    var v=new TekuTekuBeastView();v.live=s;v.beast=s.enableDev();v.openMenu("Reset scenario");v.selection=1;v.selectAction();
    Test.assert(v.beast.dev);Test.assertEqual(v.beast.stage(),0);Test.assertEqual(v.beast.growth(),0l);Test.assertEqual(v.beast.xp(),3000l);
    v.beast.careReward(300,0);v.beast.jump(7*3600);Test.assertEqual(v.beast.stage(),0);
    v.beast.jump(3600);Test.assertEqual(v.beast.stage(),1);Test.assertEqual(s.store.read("v4")["stageFloor"],1);return true;
}
(:test)
function nonStepActivityAndCollectionTest(logger){
    var s=TestSupport.fixture();var day=s.today();s.activityRewards(day,0,0,0);s.activityRewards(day,0,50,2500);
    Test.assertEqual(s.xp(),0l);Test.assertEqual(s.number("activityBonus"),5000l);Test.assertEqual(s.number("adventure"),5);
    s.activityRewards(day,0,50,2500);Test.assertEqual(s.number("activityBonus"),5000l);
    for(var i=0;i<8;i++){s.data["adventure"]++;s.explore(0);}Test.assertEqual(s.number("discoveryMask"),255);
    s.data["fullness"]=50;s.useItem(0);Test.assertEqual(s.number("discoveryMask"),255);Test.assertEqual(s.xp(),0l);return true;
}
(:test)
function foregroundEvolutionTest(logger){
    var s=TestSupport.fixture();s.testNow+=86400;s.syncToday();Test.assertEqual(s.number("evolutionPending"),1);
    var view=new TekuTekuBeastView();view.beast=s;view.page=2;view.consumeEvolution();
    Test.assertEqual(s.number("evolutionPending"),0);Test.assert(view.animation.equals("evolve"));Test.assertEqual(view.page,0);
    s.tick();Test.assertEqual(s.number("evolutionPending"),0);Test.assertEqual(s.xp(),0l);return true;
}
(:test)
function foregroundTimerLifecycleTest(logger){
    var app=Toybox.Application.getApp();var prior=app.activeView;
    var view=new TekuTekuBeastView();view.beast=TestSupport.fixture();view.onShow();
    var started=view.refresher!=null;
    view.beast.data["stageFloor"]=1;view.beast.data["motion"]=2;view.beast.data["energy"]=80;view.beast.data["sleepMode"]=2;
    view.tick=0;view.switchPage(1);Test.assertEqual(view.timerPeriod,5000);
    view.back();Test.assertEqual(view.timerPeriod,250);
    view.openMenu("Actions");view.tunePetTimer();Test.assertEqual(view.timerPeriod,5000);
    view.back();Test.assertEqual(view.timerPeriod,250);
    app.onInactive(null);var inactiveStopped=view.refresher==null;
    view.switchPage(1);view.back();Test.assert(view.refresher==null);
    app.onActive(null);var resumed=view.refresher!=null;view.onHide();
    var game=new BeastGameView(view.beast,0);game.onShow();game.onHide();
    var reconciler=new TekuTekuBeastState();reconciler.store=view.beast.store;
    reconciler.skipWatch=true;reconciler.testNow=view.beast.testNow;reconciler.start();
    reconciler.observe(reconciler.today(),5000);reconciler.commit();
    game.onShow();var caughtUp=game.beast.xp()==5000l;game.onHide();
    var gameStopped=game.refresher==null;app.activeView=prior;
    Test.assert(started && inactiveStopped && resumed && view.refresher==null && gameStopped);
    Test.assert(caughtUp);
    return true;
}

(:test)
function v04UpgradePreservationTest(logger){
    var old=TestSupport.fixture();old.observe(old.today(),5974);old.data["family"]=2;old.data["stageFloor"]=3;
    old.data["friendship"]=77;old.data["collection"]=7;old.data["rareCollection"]=2;old.data["items"][6]=8;
    old.data["snacks"]=5;old.data["careGrowth"]=250l;old.data["activityBonus"]=3000l;old.commit();
    var saved=old.store.read("v4");
    var newKeys=["sleepMode","bedMinute","wakeMinute","watchBed","watchWake","nextBed","nextWake","scheduleAt","sleepSource","autoLights","lights","lightsUntil","vibeStyle","gameSerial","gameDone","session","sessions","gameClaims","easy","v5"];
    for(var i=0;i<newKeys.size();i++){saved.remove(newKeys[i]);}
    old.store.write("v4",saved);var restored=new TekuTekuBeastState();restored.store=old.store;restored.skipWatch=true;restored.testNow=old.testNow;restored.start();
    Test.assertEqual(restored.xp(),5974l);Test.assertEqual(restored.stage(),3);Test.assertEqual(restored.family(),2);
    Test.assertEqual(restored.friendship(),77);Test.assertEqual(restored.snacks(),5);Test.assertEqual(restored.number("collection"),7);
    Test.assertEqual(restored.number("rareCollection"),2);Test.assertEqual(restored.data["items"][6],8);
    Test.assertEqual(restored.number("careGrowth"),250l);Test.assertEqual(restored.number("activityBonus"),3000l);
    Test.assertEqual(restored.data["counts"][old.today()%32],5974);Test.assertEqual(restored.number("version"),4);
    Test.assertEqual(restored.data["sessions"].size(),3);restored.commit();restored.data=null;restored.start();
    Test.assertEqual(restored.number("gameSerial"),0);Test.assertEqual(restored.xp(),5974l);return true;
}
(:test)
function scheduledSleepAndLightsTest(logger){
    var s=TestSupport.fixture();s.data["sleepMode"]=1;s.data["bedMinute"]=1320;s.data["wakeMinute"]=420;
    s.testNow+=((1320-BeastSleep.minuteAt(s.now())+1440)%1440)*60;
    s.data["lastCare"]=s.now();s.data["energy"]=0;s.data["poop"]=2;Test.assert(s.isNight());Test.assert(s.isDark());Test.assert(s.mood().equals("ASLEEP"));
    var v=new TekuTekuBeastView();v.beast=s;v.animation="happy";v.animationTicks=12;Test.assert(v.visualState().equals("sleep"));
    s.toggleLights();Test.assert(!s.isDark());Test.assert(s.isNight());s.testNow+=8*3600;s.tick();Test.assert(s.number("energy")>=64);
    Test.assert(s.isNight());Test.assert(s.isDark());s.testNow+=3600;s.tick();Test.assert(!s.isNight());
    s.data["poop"]=0;s.data["energy"]=0;Test.assert(s.mood().equals("SLEEPY"));Test.assert(v.visualState().equals("tired"));
    s.rest();Test.assert(s.mood().equals("RESTING"));var energy=s.number("energy");s.testNow-=3600;s.tick();Test.assertEqual(s.number("energy"),energy);
    s.data["sleepMode"]=2;s.data["sleepUntil"]=0l;s.data["energy"]=80;Test.assert(!s.isNight());return true;
}
(:test)
function sleepUpcomingFallbackTest(logger){
    Test.assert(!BeastSleep.validSchedule(0,0));Test.assert(!BeastSleep.validSchedule(1441,420));Test.assert(BeastSleep.validSchedule(1320,420));
    var s=TestSupport.fixture();s.data["nextBed"]=s.now()+18*3600;s.data["nextWake"]=s.now()+2*3600;
    Test.assert(s.isNight());s.data["nextBed"]=s.now()+2*3600;s.data["nextWake"]=s.now()+10*3600;Test.assert(!s.isNight());
    s.data["nextBed"]=0l;s.data["nextWake"]=0l;s.data["watchBed"]=0;s.data["watchWake"]=1439;
    Test.assert(s.isNight());s.data["watchWake"]=0;Test.assert(!s.isNight());
    Test.assert(BeastSleep.inWindow(60,1320,420));Test.assert(!BeastSleep.inWindow(600,1320,420));
    Test.assert(BeastSleep.inWindow(600,540,1020));
    s.data["sleepMode"]=1;s.data["bedMinute"]=1320;s.data["wakeMinute"]=420;
    s.testNow+=((1320-BeastSleep.minuteAt(s.now())+1440)%1440)*60;
    s.data["lastCare"]=s.now();s.data["energy"]=0;s.data["poop"]=0;s.data["fullness"]=80;s.data["friendship"]=25;
    s.testNow+=9*3600;var forecast=BeastSleep.previewMood(s.data,s.now());Test.assertEqual(s.number("energy"),0);
    Test.assert(BeastSleep.forecastEnergy(s.data,s.now())>=64);s.tick();Test.assert(s.mood().equals(forecast));return true;
}
(:test)
function gameSessionAtomicityTest(logger){
    var s=TestSupport.fixture();s.data["adventure"]=2;s.commit();var trip=s.beginSession(2);var id=trip["id"];
    Test.assertEqual(s.number("adventure"),1);Test.assertEqual(s.beginSession(2)["id"],id);Test.assertEqual(s.number("adventure"),1);
    trip["route"]=3;trip["node"]=2;trip["finds"]=3;Test.assert(s.saveSession(trip));
    s.data=null;s.start();Test.assertEqual(s.data["sessions"][2]["route"],3);Test.assertEqual(s.number("adventure"),1);
    var answer=s.completeSession(trip,true);Test.assert(answer.find("FOUND ")==0);Test.assertEqual(s.number("encounters"),1);
    Test.assertEqual(s.friendship(),1);
    Test.assert(s.completeSession(trip,true).equals("ALREADY SAVED"));Test.assert(!s.saveSession(trip));Test.assertEqual(s.number("encounters"),1);
    Test.assertEqual(s.friendship(),1);
    Test.assertEqual(s.xp(),0l);var arcade=s.beginSession(0);var slots=s.number("games");s.completeSession(arcade,true);s.completeSession(arcade,true);
    Test.assertEqual(s.number("games"),slots+1);Test.assertEqual(s.xp(),0l);return true;
}
(:test)
function gameRetryReplayAndSuspendTest(logger){
    var s=TestSupport.fixture();s.data["haptics"]=0;var game=new BeastGameView(s,1);game.selectAction();game.phase=2;
    var first=game.sequence[0];game.memoryInput((first+1)%3);Test.assertEqual(game.phase,4);Test.assert(game.replayRound);Test.assertEqual(s.number("games"),0);
    game.continueMemory();Test.assertEqual(game.phase,1);game.phase=2;game.cursor=0;game.memoryInput((first+1)%3);Test.assert(!game.replayRound);
    game.continueMemory();Test.assertEqual(game.round,1);game.onHide();var resumed=new BeastGameView(s,1);resumed.onShow();resumed.onHide();
    Test.assertEqual(resumed.round,1);Test.assertEqual(resumed.retries,0);Test.assertEqual(s.number("games"),0);
    var trip=new BeastGameView(s,2);s.data["adventure"]=1;trip.trail=2;trip.selectAction();
    for(var stop=0;stop<3;stop++){for(var t=0;t<12;t++){trip.refresh();}Test.assertEqual(trip.phase,2);trip.choice=stop%2;trip.selectAction();Test.assertEqual(trip.phase,4);trip.nextTrail();}
    Test.assertEqual(trip.phase,3);Test.assertEqual(s.number("adventure"),0);Test.assertEqual(s.number("encounters"),1);
    Test.assertEqual(s.number("games"),0);Test.assertEqual(s.xp(),0l);
    // Simulate interruption after the atomic session/debit, before the view's
    // first sequence/target/travel checkpoint. Reopening must finish setup.
    var cold=TestSupport.fixture();var initialMemory=cold.beginSession(1);
    var recoveredMemory=new BeastGameView(cold,1);recoveredMemory.onShow();recoveredMemory.onHide();
    Test.assertEqual(recoveredMemory.sequence.size(),3);Test.assertEqual(recoveredMemory.session["id"],initialMemory["id"]);
    cold.data["adventure"]=2;var initialTrip=cold.beginSession(2);Test.assertEqual(initialTrip["phase"],5);
    initialTrip["phase"]=1;cold.saveSession(initialTrip); // repair an older incomplete start too
    var recoveredTrip=new BeastGameView(cold,2);recoveredTrip.onShow();recoveredTrip.onHide();
    Test.assertEqual(recoveredTrip.phase,5);Test.assertEqual(cold.number("adventure"),1);
    Test.assertEqual(recoveredTrip.session["id"],initialTrip["id"]);
    var initialBounce=cold.beginSession(0);var recoveredBounce=new BeastGameView(cold,0);
    recoveredBounce.onShow();recoveredBounce.onHide();Test.assert(cold.data["sessions"][0].hasKey("target"));
    Test.assertEqual(cold.data["sessions"][0]["seed"],(initialBounce["seed"]*17+11)%65521);
    Test.assertEqual(cold.number("games"),0);Test.assertEqual(cold.xp(),0l);return true;
}
(:test)
function devNewSystemsIsolationTest(logger){
    var s=TestSupport.fixture();s.observe(s.today(),4200);s.commit();var d=s.enableDev();d.simulateSleep(true);
    d.toggleLights();Test.assert(d.wakeUp());d.data["adventure"]=20;var trip=d.beginSession(2);trip["finds"]=3;d.completeSession(trip,true);
    d.data["easy"]=1;d.jump(7*86400);d.commit();
    var restored=new TekuTekuBeastState();restored.store=s.store;restored.testNow=s.testNow;restored.skipWatch=true;restored.start();
    Test.assertEqual(restored.number("adventure"),0);Test.assertEqual(restored.number("encounters"),0);Test.assertEqual(restored.number("easy"),0);
    Test.assertEqual(restored.number("sleepMode"),0);Test.assertEqual(restored.number("lightsUntil"),0l);Test.assertEqual(restored.xp(),4200l);
    Test.assertEqual(restored.number("gameSerial"),0);return true;
}
(:test)
function sessionMidnightAndPracticeTest(logger){
    var s=TestSupport.fixture();s.data["games"]=3;var session=s.beginSession(0);var energy=s.number("energy");
    Test.assert(s.completeSession(session,true).equals("PRACTICE"));Test.assertEqual(s.number("energy"),energy);
    var next=s.beginSession(1);s.testNow+=86400;s.tick();Test.assertEqual(s.number("games"),0);
    s.completeSession(next,true);Test.assertEqual(s.number("games"),1);s.data=null;s.start();s.completeSession(next,true);
    Test.assertEqual(s.number("games"),1);var trip=s.beginSession(2);Test.assert(trip["practice"]);
    trip["finds"]=9;Test.assert(s.completeSession(trip,true).equals("SCOUT COMPLETE"));
    Test.assertEqual(s.number("encounters"),0);Test.assertEqual(s.number("adventure"),0);Test.assertEqual(s.number("discoveryMask"),0);
    Test.assertEqual(s.xp(),0l);return true;
}
(:test)
function quietBedtimeFeedbackTest(logger){
    var s=TestSupport.fixture();var d=s.enableDev();d.simulateSleep(true);d.data["sound"]=1;d.data["haptics"]=1;
    new FeedbackManager().testCue(d,true);Test.assert(FeedbackManager.lastStatus.equals("BEDTIME: QUIET"));
    Test.assertEqual(d.number("sound"),1);Test.assertEqual(d.number("haptics"),1);
    d.simulateSleep(false);d.data["sound"]=0;d.data["haptics"]=0;FeedbackManager.lastCue=-2000;
    new FeedbackManager().cue(d,"eat");Test.assert(FeedbackManager.lastStatus.equals("FEEDBACK OFF"));
    Test.assertEqual(s.xp(),0l);return true;
}
