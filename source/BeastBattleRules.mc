// Portable battle protocol v1: plain dictionaries/arrays and caller-owned seeds.
// No clocks, storage, Garmin APIs or rewards are mutated. turn() returns a deep
// battle copy; only the app orchestrator may save/claim its terminal outcome.
module BeastBattleRules {
    function min(a,b){return a<b?a:b;}
    function max(a,b){return a>b?a:b;}
    function clamp(n,lo,hi){return min(hi,max(lo,n));}
    function nextSeed(seed){return ((seed%BeastBattleData.SEED_MOD)*BeastBattleData.SEED_MULT+BeastBattleData.SEED_ADD)%BeastBattleData.SEED_MOD;}
    function level(xp){return min(BeastBattleData.LEVEL_CAP,(max(0,xp)/BeastBattleData.LEVEL_XP).toNumber());}
    function fighter(stage,family,rare,friendship,personality,battleXp,mastery){
        if(stage<=0){return null;}
        stage=clamp(stage,1,5);family=clamp(family,0,4);
        var form=BeastBattleMoves.form(stage,family,rare);var trained=[];
        for(var i=0;i<4;i++){
            var n=mastery!=null && mastery.size()>form*4+i?mastery[form*4+i]:0;
            trained.add(clamp(n,0,BeastBattleData.MASTERY_CAP));
        }
        var temper=0;
        if(personality!=null && personality.size()>=4){for(var j=1;j<4;j++){if(personality[j]>personality[temper]){temper=j;}}}
        var hp=BeastBattleData.HP_BASE+stage*BeastBattleData.HP_STAGE+level(battleXp);
        return {"form"=>form,"family"=>family,"stage"=>stage,"maxHp"=>hp,"hp"=>hp,
            "power"=>BeastBattleData.POWER_BASE+stage+(level(battleXp)/BeastBattleData.POWER_LEVEL_DIV).toNumber(),"armour"=>(stage/BeastBattleData.ARMOUR_STAGE_DIV).toNumber(),
            "friendship"=>clamp(friendship,0,100),"temper"=>temper,"guard"=>0,"buff"=>0,
            "cooldown"=>0,"mastery"=>trained};
    }
    function copyActor(actor){
        var result={};var keys=actor.keys();
        for(var i=0;i<keys.size();i++){var k=keys[i];result[k]=actor[k];}
        result["mastery"]=[];for(var j=0;j<4;j++){result["mastery"].add(actor["mastery"][j]);}return result;
    }
    function create(id,seed,player,opponent){
        if(player==null || opponent==null){return null;}
        return {"v"=>BeastBattleData.PROTOCOL,"id"=>id,"seed"=>max(0,seed).toNumber()%BeastBattleData.SEED_MOD,"turn"=>0,"status"=>0,
            "actors"=>[copyActor(player),copyActor(opponent)],"events"=>[],"uses"=>[0,0,0,0]};
    }
    // Language types only: no JSON codec, platform clock, storage or transport.
    function integer(n,lo,hi){
        return (n instanceof Toybox.Lang.Number || n instanceof Toybox.Lang.Long ||
            n instanceof Toybox.Lang.Float || n instanceof Toybox.Lang.Double) &&
            n>=lo && n<=hi && n==n.toNumber();
    }
    function versioned(state){return state instanceof Toybox.Lang.Dictionary && state.hasKey("v") && state["v"]==BeastBattleData.PROTOCOL;}
    function intArray(values,size,lo,hi){
        if(!(values instanceof Toybox.Lang.Array) || values.size()!=size){return false;}
        for(var i=0;i<size;i++){if(!integer(values[i],lo,hi)){return false;}}return true;
    }
    function validActor(actor){
        if(!(actor instanceof Toybox.Lang.Dictionary) || actor.size()!=13){return false;}
        var keys=["form","family","stage","maxHp","hp","power","armour","friendship","temper","guard","buff","cooldown"];
        var lo=[0,0,1,42,0,3,0,0,0,0,0,0];var hi=[17,4,5,70,70,11,2,100,3,1,2,2];
        for(var i=0;i<keys.size();i++){if(!actor.hasKey(keys[i]) || !integer(actor[keys[i]],lo[i],hi[i])){return false;}}
        if(!actor.hasKey("mastery") || !intArray(actor["mastery"],4,0,BeastBattleData.MASTERY_CAP)){return false;}
        var form=actor["form"].toNumber();var rare=form>=2 && (form-2)%4==3?1:0;
        return actor["hp"]<=actor["maxHp"] && form==BeastBattleMoves.form(actor["stage"],actor["family"],rare);
    }
    function importState(state){
        // Validate at the serialization boundary; trusted live turns do not pay
        // for a full schema traversal. Unknown versions are never reset to v1.
        if(!versioned(state) || state.size()!=8){return null;}
        var keys=["v","id","seed","turn","status"];var hi=[1,2147483647,65520,20,3];
        for(var i=0;i<keys.size();i++){if(!state.hasKey(keys[i]) || !integer(state[keys[i]],i<2?1:0,hi[i])){return null;}}
        if(!state.hasKey("actors") || !(state["actors"] instanceof Toybox.Lang.Array) || state["actors"].size()!=2){return null;}
        for(var j=0;j<2;j++){if(!validActor(state["actors"][j])){return null;}}
        if(!state.hasKey("uses") || !intArray(state["uses"],4,0,20)){return null;}
        if(state["uses"][0]+state["uses"][1]+state["uses"][2]+state["uses"][3]!=state["turn"]){return null;}
        if(!state.hasKey("events") || !(state["events"] instanceof Toybox.Lang.Array) || state["events"].size()>2){return null;}
        if((state["turn"]==0)!=(state["events"].size()==0)){return null;}
        for(var e=0;e<state["events"].size();e++){
            var event=state["events"][e];
            if(!(event instanceof Toybox.Lang.Dictionary) || event.size()!=4){return null;}
            var fields=["actor","move","damage","effect"];var maxes=[1,71,70,3];
            for(var f=0;f<4;f++){if(!event.hasKey(fields[f]) || !integer(event[fields[f]],0,maxes[f])){return null;}}
            if(event["actor"]!=e || event["effect"]!=event["move"].toNumber()%4 ||
                (event["move"]/4).toNumber()!=state["actors"][e]["form"]){return null;}
            if((event["effect"]==1 || event["effect"]==2) && event["damage"]!=0){return null;}
        }
        var p=state["actors"][0]["hp"];var foe=state["actors"][1]["hp"];var status=state["status"];
        if((status==0 && (p==0 || foe==0 || state["turn"]>=20)) ||
            (status==1 && (p==0 || foe!=0)) || (status==2 && (p!=0 || foe==0)) ||
            (status==3 && (p==0 || foe==0 || state["turn"]!=20))){return null;}
        var result=copy(state);
        for(var k=0;k<keys.size();k++){result[keys[k]]=result[keys[k]].toNumber();}
        for(var a=0;a<2;a++){
            var actor=result["actors"][a];var names=actor.keys();
            for(var n=0;n<names.size();n++){var key=names[n];if(!key.equals("mastery")){actor[key]=actor[key].toNumber();}}
            for(var m=0;m<4;m++){actor["mastery"][m]=actor["mastery"][m].toNumber();}
        }
        for(var u=0;u<4;u++){result["uses"][u]=result["uses"][u].toNumber();}
        for(var v=0;v<result["events"].size();v++){
            var evt=result["events"][v];var fields=evt.keys();for(var z=0;z<fields.size();z++){evt[fields[z]]=evt[fields[z]].toNumber();}
        }
        return result;
    }
    function exportState(state){
        if(!versioned(state)){return null;}
        // Strip storage metadata, but validate raw core values BEFORE copy()
        // can normalize a seed. Malformed exports must not silently repair data.
        var core={};var fields=["v","id","seed","turn","status","actors","events","uses"];
        for(var i=0;i<fields.size();i++){if(!state.hasKey(fields[i])){return null;}core[fields[i]]=state[fields[i]];}
        return importState(core);
    }
    function copy(state){
        var result=create(state["id"],state["seed"],state["actors"][0],state["actors"][1]);
        result["turn"]=state["turn"];result["status"]=state["status"];
        for(var i=0;i<4;i++){result["uses"][i]=state["uses"][i];}
        for(var j=0;j<state["events"].size();j++){
            var e=state["events"][j];result["events"].add({"actor"=>e["actor"],"move"=>e["move"],"damage"=>e["damage"],"effect"=>e["effect"]});
        }
        return result;
    }
    function availableAt(state,index,slot){
        return versioned(state) && integer(index,0,1) && integer(slot,0,3) && state["status"]==0 &&
            (slot!=3 || state["actors"][index.toNumber()]["cooldown"]==0);
    }
    function available(state,slot){return availableAt(state,0,slot);}
    // Ring affinity: Grove > Tide > Ember > Wisp > Grove; never blocks a move.
    function affinity(a,b){
        if(a==0 || b==0 || a==b){return 0;}
        var prey=BeastBattleData.prey();return prey[a]==b?BeastBattleData.AFFINITY_DAMAGE:(prey[b]==a?-BeastBattleData.AFFINITY_DAMAGE:0);
    }
    function ai(state){
        var actor=state["actors"][1];var foe=state["actors"][0];var roll=nextSeed(state["seed"])%BeastBattleData.AI_ROLL_MOD;
        if(actor["hp"]*BeastBattleData.AI_LOW_HP_DIV<actor["maxHp"] && actor["guard"]==0 && roll<BeastBattleData.AI_GUARD_ROLL){return 1;}
        if(actor["cooldown"]==0 && (roll<BeastBattleData.AI_SIGNATURE_ROLL || foe["hp"]<BeastBattleData.AI_FINISH_HP)){return 3;}
        if(actor["buff"]==0 && roll>=BeastBattleData.AI_BUFF_ROLL){return 2;}
        return 0;
    }
    function act(state,index,slot){
        var actor=state["actors"][index];var foe=state["actors"][1-index];
        var event={"actor"=>index,"move"=>BeastBattleMoves.id(actor["form"],slot),"damage"=>0,"effect"=>slot};
        if(actor["cooldown"]>0){actor["cooldown"]--;}
        if(slot==1){actor["guard"]=1;}
        else if(slot==2){actor["buff"]=BeastBattleData.BUFF_HITS;}
        else{
            state["seed"]=nextSeed(state["seed"]);
            var trained=min(BeastBattleData.MASTERY_DAMAGE_CAP,(actor["mastery"][slot]/BeastBattleData.MASTERY_DIV).toNumber());
            var bond=(actor["friendship"]/BeastBattleData.BOND_DIV).toNumber();
            var personality=(actor["temper"]==1?1:0)+(slot==3 && actor["temper"]==3?1:0);
            var damage=(slot==3?BeastBattleData.SIGNATURE_BASE:BeastBattleData.DAMAGE_BASE)+actor["power"]+trained+bond+personality+
                affinity(actor["family"],foe["family"])+(state["seed"]%BeastBattleData.DAMAGE_VARIANCE)-foe["armour"];
            if(actor["buff"]>0){damage+=BeastBattleData.BUFF_DAMAGE+(actor["temper"]==2?1:0);actor["buff"]--;}
            if(foe["guard"]>0){damage=(damage*(foe["temper"]==0?BeastBattleData.GUARD_CALM_PERCENT:BeastBattleData.GUARD_PERCENT)/100).toNumber();foe["guard"]=0;}
            damage=max(1,damage);event["damage"]=min(foe["hp"],damage);foe["hp"]=max(0,foe["hp"]-damage);
            if(slot==3){actor["cooldown"]=BeastBattleData.SIGNATURE_COOLDOWN;}
        }
        state["events"].add(event);
    }
    function turn(state,slot){
        if(!versioned(state)){return null;}
        if(!available(state,slot)){return copy(state);}
        // Keep the existing pre-turn AI choice and seed order exactly intact.
        return pairedTurn(state,slot,ai(state));
    }
    // Friend battles supply both choices; every effect remains in the same act().
    // Actor zero acts first, exactly as in wild battles. No rewards are applied.
    function pairedTurn(state,first,second){
        if(!versioned(state)){return null;}
        var result=copy(state);
        if(!availableAt(state,0,first) || !availableAt(state,1,second)){return result;}
        first=first.toNumber();second=second.toNumber();
        result["events"]=[];result["turn"]++;result["uses"][first]++;
        act(result,0,first);
        if(result["actors"][1]["hp"]<=0){result["status"]=1;return result;}
        act(result,1,second);
        if(result["actors"][0]["hp"]<=0){result["status"]=2;}
        else if(result["turn"]>=BeastBattleData.MAX_TURNS){result["status"]=3;}
        return result;
    }
    function xpReward(state){return state["status"]==0?0:(state["status"]==1?BeastBattleData.WIN_XP:(state["status"]==2?BeastBattleData.LOSS_XP:BeastBattleData.DRAW_XP));}
    function rewardEligible(status,turn,practice,rewardedToday){
        return status>=1 && status<=3 && turn>0 && !practice &&
            rewardedToday>=0 && rewardedToday<BeastBattleData.DAILY_REWARD_CAP;
    }
    // Increment vector, not a replacement inventory; grant once at claim boundary.
    function masteryReward(state){
        var result=[];for(var i=0;i<72;i++){result.add(0);}
        if(state["status"]==0){return result;}
        var form=state["actors"][0]["form"];
        for(var j=0;j<4;j++){result[form*4+j]=min(BeastBattleData.MASTERY_MATCH_CAP,state["uses"][j]);}
        return result;
    }
}
