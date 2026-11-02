// Foreground transaction boundary. One separate atomic document owns encounters,
// turns AND their claims; the background/Glance never load this record.
class BeastBattle {
    var beast;var data;var baseline;var generation;
    function initialize(model){
        beast=model;beast.start();generation=beast.number("petSerial");
        data=beast.battleData;
        if(data==null){data=beast.store.copy(beast.store.read("battle.v1"));}
        baseline=beast.store.copy(data);
        if(data==null){
            var mastery=[];for(var i=0;i<72;i++){mastery.add(0);}
            data={"v"=>1,"day"=>0,"serial"=>0,"queue"=>[],"active"=>null,"xp"=>0,
                "mastery"=>mastery,"claim"=>0,"rewarded"=>0,"seen"=>0,"wins"=>0,
                "stepMark"=>(beast.xp()/2500).toNumber(),"stepOffers"=>0,
                "trailMark"=>beast.number("encounters"),"careMark"=>(beast.number("careToday")/100).toNumber()};
        }
        // Additive owner marker: legacy matches belong to the current pet.
        // A new generation keeps account progress/opportunities but retires its
        // predecessor's temporary combat snapshot, even after a crash/reload.
        if(!data.hasKey("petSerial") || data["petSerial"]!=generation){
            data=beast.store.copy(data);
            if(data.hasKey("petSerial")){data["active"]=null;}
            data["petSerial"]=generation;
        }
        discover();
    }
    function isCurrent(){return generation==beast.number("petSerial");}
    function commit(){
        if(!isCurrent()){return;}
        if(!beast.store.same(baseline,data)){
            // One independent snapshot serves both persistence and comparison.
            // Live data remains separate; failed writes leave baseline intact.
            var snapshot=beast.store.copy(data);
            if(!beast.dev){beast.store.write("battle.v1",snapshot);}
            baseline=snapshot;
        }
        beast.battleData=data;
    }
    function offer(source){
        if(!isCurrent()){return;}
        if(data["queue"].size()>=4){return;}
        data["serial"]++;var seed=(((data["serial"]%65521)*719+(beast.xp()%65521)+source*101)%65521).toNumber();
        data["queue"].add({"id"=>data["serial"],"seed"=>seed,"source"=>source});
    }
    function discover(){
        if(!isCurrent()){return;}
        var day=beast.today();
        // Monotonic local-day watermark: rollback cannot farm daily encounters.
        if(day>data["day"]){
            // A battle can remain open across midnight. Roll the pet's care
            // day first: yesterday's care must not become new-day encounters.
            // tick() is lazy game catch-up, not a Garmin query or storage write.
            beast.tick();
            data["day"]=day;data["rewarded"]=0;data["stepOffers"]=0;
            data["careMark"]=0;offer(0); // Daily accessible trail, no steps needed.
        }
        var step=(beast.xp()/2500).toNumber();
        if(step>data["stepMark"]){
            var count=beast.min(step-data["stepMark"],2-data["stepOffers"]);
            for(var i=0;i<count;i++){offer(1);}data["stepOffers"]+=count;data["stepMark"]=step;
        }
        var trails=beast.number("encounters");
        if(trails>data["trailMark"]){
            for(var j=0;j<beast.min(2,trails-data["trailMark"]);j++){offer(2);}data["trailMark"]=trails;
        }
        var care=(beast.number("careToday")/100).toNumber();
        if(day==data["day"] && care>data["careMark"]){
            for(var k=0;k<beast.min(3,care-data["careMark"]);k++){offer(3);}data["careMark"]=care;
        }
        commit();
    }
    function battleSession(){if(!isCurrent()){return null;}return data["active"]==null?null:beast.store.copy(data["active"]);}
    function hasUnfinishedBattle(){
        if(!isCurrent()){return false;}
        var m=data["active"];
        return BeastBattleRules.versioned(m) && m.hasKey("status") && m["status"]==0 &&
            m.hasKey("claimed") && !m["claimed"] && m.hasKey("id") && m["id"]>data["claim"] &&
            m.hasKey("actors") && m["actors"] instanceof Toybox.Lang.Array && m["actors"].size()==2 &&
            BeastBattleRules.validActor(m["actors"][0]) && BeastBattleRules.validActor(m["actors"][1]) &&
            m["actors"][0]["hp"]>0 && m["actors"][1]["hp"]>0;
    }
    function clearFinishedBattle(){
        if(!isCurrent()){return false;}
        var m=data["active"];
        if(m!=null && (m["claimed"] || m["id"]<=data["claim"])){data["active"]=null;commit();return true;}
        return false;
    }
    function battleQueueCount(){return data["queue"].size();}
    function battleXp(){return data["xp"];}
    function battleMastery(slot){var form=BeastBattleMoves.form(beast.stage(),beast.family(),beast.number("rare"));return form<0?0:data["mastery"][form*4+slot];}
    function makeBattle(encounter,practice){
        var stage=beast.stage();var family=stage<3?0:1+encounter["seed"]%4;
        var p=BeastBattleRules.fighter(stage,beast.family(),beast.number("rare"),beast.friendship(),beast.data["personality"],data["xp"],data["mastery"]);
        var temperament=[0,0,0,0];temperament[encounter["seed"]%4]=1;
        var e=BeastBattleRules.fighter(stage,family,0,30,temperament,0,null);
        var match=BeastBattleRules.create(encounter["id"],encounter["seed"],p,e);
        match["practice"]=practice;match["claimed"]=false;match["outcome"]="";
        return match;
    }
    function beginBattle(){
        if(!isCurrent()){return null;}
        if(beast.isSleeping() || beast.stage()==0){return null;}
        clearFinishedBattle();
        if(data["active"]!=null){
            if(data["active"]["status"]==0 || !data["active"]["claimed"]){return battleSession();}
            data["active"]=null;
        }
        if(data["queue"].size()==0){commit();return null;}
        var next=data["queue"][0];data["queue"].remove(next);
        data["serial"]++;next["id"]=data["serial"];
        data["active"]=makeBattle(next,false);commit();return battleSession();
    }
    function practiceBattle(){
        if(!isCurrent()){return null;}
        if(beast.isSleeping() || beast.stage()==0){return null;}
        clearFinishedBattle();
        if(data["active"]!=null && !data["active"]["claimed"]){return battleSession();}
        data["serial"]++;var encounter={"id"=>data["serial"],"seed"=>(data["serial"]*719)%65521};
        data["active"]=makeBattle(encounter,true);commit();return battleSession();
    }
    function battleTurn(slot){
        if(!isCurrent()){return null;}
        var current=data["active"];
        if(beast.isSleeping() || current==null){return null;}
        if(current["claimed"] || current["id"]<=data["claim"] || current["status"]!=0){return battleSession();}
        if(!BeastBattleRules.available(current,slot)){return battleSession();}
        var next=BeastBattleRules.turn(current,slot);
        // UI/persistence metadata is outside the deterministic combat protocol.
        next["practice"]=current["practice"];next["claimed"]=false;next["outcome"]="";
        data["active"]=next;
        try{commit();}catch(e instanceof Toybox.Lang.Exception){
            // Rules returned a detached turn. Restore the shared cache pointer
            // on failure so another controller cannot adopt an unsaved turn.
            data["active"]=current;throw e;
        }
        return battleSession();
    }
    function finishBattle(){
        if(beast.isSleeping()){return "Beast is asleep.";}
        return claimFinishedBattle();
    }
    // Archive may settle an already-earned result during sleep; it never runs
    // a combat turn or grants pet growth, items, energy or friendship.
    function claimFinishedBattle(){
        if(!isCurrent()){return "MATCH RETIRED";}
        var match=data["active"];
        if(match==null || match["status"]==0){return "MATCH PAUSED";}
        if(match["claimed"] || match["id"]<=data["claim"]){return match["outcome"];}
        // Refresh bounded opportunities and the reward day only for a new
        // claim. Reopening an already-claimed result stays a complete no-op.
        discover();
        // The candidate is the same independent snapshot a normal commit uses.
        // Never expose an unsaved claim through the shared foreground cache.
        var next=beast.store.copy(data);var result=next["active"];var xp=0;
        if(BeastBattleRules.rewardEligible(result["status"],result["turn"],result["practice"],next["rewarded"])){
            xp=BeastBattleRules.xpReward(result);next["xp"]+=xp;next["rewarded"]++;
            var increments=BeastBattleRules.masteryReward(result);
            for(var i=0;i<72;i++){next["mastery"][i]=beast.min(BeastBattleData.MASTERY_CAP,next["mastery"][i]+increments[i]);}
            next["seen"]|=1<<result["actors"][1]["form"];
            if(result["status"]==1){next["wins"]++;}
        }
        result["outcome"]=xp>0?"+"+xp+" BATTLE XP":"PRACTICE COMPLETE";
        result["claimed"]=true;next["claim"]=result["id"];
        var fields=["xp","rewarded","seen","wins","claim"];
        if(!beast.dev){beast.store.write("battle.v1",next);}
        // Publish only after success, preserving shared object/array identities.
        // Failure above leaves live data, cache and dirty baseline unclaimed.
        for(var j=0;j<fields.size();j++){data[fields[j]]=next[fields[j]];}
        for(var k=0;k<72;k++){data["mastery"][k]=next["mastery"][k];}
        match["outcome"]=result["outcome"];match["claimed"]=true;
        baseline=next;beast.battleData=data;return match["outcome"];
    }
    function postponeBattle(){commit();}
    function abandonBattle(id){
        if(!isCurrent()){return false;}
        var current=data["active"];
        if(current==null || current["id"]!=id){return false;}
        // A committed KO/draw is already a genuine result, not a forfeit.
        // Settle it once rather than letting menu actions erase earned rewards.
        if(current["status"]!=0){
            finishBattle();if(!current["claimed"]){return false;}
        }
        // Encounter was spent on entry. No consolation XP, mastery, win/loss,
        // refund or requeued opponent for an abandoned match.
        data["claim"]=beast.max(data["claim"],id);data["active"]=null;commit();return true;
    }
    function declineEncounter(){
        if(!isCurrent()){return false;}
        if(data["queue"].size()>0){data["queue"].remove(data["queue"][0]);commit();return true;}return false;
    }
}
