// Portable battle protocol v1: plain dictionaries/arrays and caller-owned seeds.
// No clocks, storage, Garmin APIs or rewards are mutated. turn() returns a deep
// battle copy; only the app orchestrator may save/claim its terminal outcome.
module BeastBattleRules {
    function min(a,b){return a<b?a:b;}
    function max(a,b){return a>b?a:b;}
    function clamp(n,lo,hi){return min(hi,max(lo,n));}
    function nextSeed(seed){return ((seed%65521)*17+11)%65521;}
    function level(xp){return min(12,(max(0,xp)/80).toNumber());}
    function fighter(stage,family,rare,friendship,personality,battleXp,mastery){
        if(stage<=0){return null;}
        stage=clamp(stage,1,5);family=clamp(family,0,4);
        var form=BeastBattleMoves.form(stage,family,rare);var trained=[];
        for(var i=0;i<4;i++){
            var n=mastery!=null && mastery.size()>form*4+i?mastery[form*4+i]:0;
            trained.add(clamp(n,0,999));
        }
        var temper=0;
        if(personality!=null && personality.size()>=4){for(var j=1;j<4;j++){if(personality[j]>personality[temper]){temper=j;}}}
        var hp=38+stage*4+level(battleXp);
        return {"form"=>form,"family"=>family,"stage"=>stage,"maxHp"=>hp,"hp"=>hp,
            "power"=>2+stage+(level(battleXp)/3).toNumber(),"armour"=>(stage/2).toNumber(),
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
        return {"v"=>1,"id"=>id,"seed"=>max(0,seed)%65521,"turn"=>0,"status"=>0,
            "actors"=>[copyActor(player),copyActor(opponent)],"events"=>[],"uses"=>[0,0,0,0]};
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
    function available(state,slot){return slot>=0 && slot<4 && state["status"]==0 && (slot!=3 || state["actors"][0]["cooldown"]==0);}
    // Ring affinity: Grove > Tide > Ember > Wisp > Grove; never blocks a move.
    function affinity(a,b){
        if(a==0 || b==0 || a==b){return 0;}
        var prey=[0,3,4,2,1];return prey[a]==b?2:(prey[b]==a?-2:0);
    }
    function ai(state){
        var actor=state["actors"][1];var foe=state["actors"][0];var roll=nextSeed(state["seed"])%10;
        if(actor["hp"]*3<actor["maxHp"] && actor["guard"]==0 && roll<3){return 1;}
        if(actor["cooldown"]==0 && (roll<5 || foe["hp"]<16)){return 3;}
        if(actor["buff"]==0 && roll>=7){return 2;}
        return 0;
    }
    function act(state,index,slot){
        var actor=state["actors"][index];var foe=state["actors"][1-index];
        var event={"actor"=>index,"move"=>BeastBattleMoves.id(actor["form"],slot),"damage"=>0,"effect"=>slot};
        if(actor["cooldown"]>0){actor["cooldown"]--;}
        if(slot==1){actor["guard"]=1;}
        else if(slot==2){actor["buff"]=2;}
        else{
            state["seed"]=nextSeed(state["seed"]);
            var trained=min(3,(actor["mastery"][slot]/10).toNumber());
            var bond=(actor["friendship"]/40).toNumber();
            var personality=(actor["temper"]==1?1:0)+(slot==3 && actor["temper"]==3?1:0);
            var damage=(slot==3?11:7)+actor["power"]+trained+bond+personality+
                affinity(actor["family"],foe["family"])+(state["seed"]%3)-foe["armour"];
            if(actor["buff"]>0){damage+=3+(actor["temper"]==2?1:0);actor["buff"]--;}
            if(foe["guard"]>0){damage=(damage*(foe["temper"]==0?35:45)/100).toNumber();foe["guard"]=0;}
            damage=max(1,damage);event["damage"]=min(foe["hp"],damage);foe["hp"]=max(0,foe["hp"]-damage);
            if(slot==3){actor["cooldown"]=2;}
        }
        state["events"].add(event);
    }
    function turn(state,slot){
        var result=copy(state);
        if(!available(state,slot)){return result;}
        // AI peeks at next seed first; player damage, then surviving opponent
        // damage each advance RNG once. Guard/buff moves consume no random draw.
        result["events"]=[];var choice=ai(result);result["turn"]++;result["uses"][slot]++;
        act(result,0,slot);
        if(result["actors"][1]["hp"]<=0){result["status"]=1;return result;}
        act(result,1,choice);
        if(result["actors"][0]["hp"]<=0){result["status"]=2;}
        else if(result["turn"]>=20){result["status"]=3;}
        return result;
    }
    function xpReward(state){return state["status"]==0?0:(state["status"]==1?12:(state["status"]==2?5:7));}
    // Increment vector, not a replacement inventory; grant once at claim boundary.
    function masteryReward(state){
        var result=[];for(var i=0;i<72;i++){result.add(0);}
        if(state["status"]==0){return result;}
        var form=state["actors"][0]["form"];
        for(var j=0;j<4;j++){result[form*4+j]=min(3,state["uses"][j]);}
        return result;
    }
}
