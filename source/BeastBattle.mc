// Foreground transaction boundary. One separate atomic document owns encounters,
// turns AND their claims; the background/Glance never load this record.
class BeastBattle {
    var beast;var data;var baseline;
    function initialize(model){
        beast=model;beast.start();
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
        discover();
    }
    function commit(){
        if(!beast.store.same(baseline,data)){
            if(!beast.dev){beast.store.write("battle.v1",beast.store.copy(data));}
            baseline=beast.store.copy(data);
        }
        beast.battleData=data;
    }
    function offer(source){
        if(data["queue"].size()>=4){return;}
        data["serial"]++;var seed=(((data["serial"]%65521)*719+(beast.xp()%65521)+source*101)%65521).toNumber();
        data["queue"].add({"id"=>data["serial"],"seed"=>seed,"source"=>source});
    }
    function discover(){
        var day=beast.today();
        // Monotonic local-day watermark: rollback cannot farm daily encounters.
        if(day>data["day"]){
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
    function battleSession(){return data["active"]==null?null:beast.store.copy(data["active"]);}
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
        if(beast.isSleeping() || beast.stage()==0){return null;}
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
        if(beast.isSleeping() || beast.stage()==0){return null;}
        if(data["active"]!=null && !data["active"]["claimed"]){return battleSession();}
        data["serial"]++;var encounter={"id"=>data["serial"],"seed"=>(data["serial"]*719)%65521};
        data["active"]=makeBattle(encounter,true);commit();return battleSession();
    }
    function battleTurn(slot){
        var current=data["active"];
        if(beast.isSleeping() || current==null){return null;}
        if(!BeastBattleRules.available(current,slot)){return battleSession();}
        var next=BeastBattleRules.turn(current,slot);
        // UI/persistence metadata is outside the deterministic combat protocol.
        next["practice"]=current["practice"];next["claimed"]=false;next["outcome"]="";
        data["active"]=next;commit();return battleSession();
    }
    function finishBattle(){
        if(beast.isSleeping()){return "Beast is asleep.";}
        var match=data["active"];
        if(match==null || match["status"]==0){return "MATCH PAUSED";}
        if(match["claimed"] || match["id"]<=data["claim"]){return match["outcome"];}
        var xp=0;
        if(BeastBattleRules.rewardEligible(match["status"],match["turn"],match["practice"],data["rewarded"])){
            xp=BeastBattleRules.xpReward(match);data["xp"]+=xp;data["rewarded"]++;
            var increments=BeastBattleRules.masteryReward(match);
            for(var i=0;i<72;i++){data["mastery"][i]=beast.min(BeastBattleData.MASTERY_CAP,data["mastery"][i]+increments[i]);}
            data["seen"]|=1<<match["actors"][1]["form"];
            if(match["status"]==1){data["wins"]++;}
        }
        match["outcome"]=xp>0?"+"+xp+" BATTLE XP":"PRACTICE COMPLETE";
        match["claimed"]=true;data["claim"]=match["id"];commit();return match["outcome"];
    }
    function postponeBattle(){commit();}
    function declineEncounter(){
        if(data["queue"].size()>0){data["queue"].remove(data["queue"][0]);commit();return true;}return false;
    }
}
