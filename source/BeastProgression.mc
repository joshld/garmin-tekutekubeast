// Platform-free rules. Inputs are the existing save document and epoch seconds;
// no clock, calendar, storage, watch API, rendering or developer overrides.
(:background)
module BeastProgression {
    function value(data,key){return data.hasKey(key)?data[key]:0;}
    function max(a,b){return a>b?a:b;}
    function min(a,b){return a<b?a:b;}
    function growth(data){return value(data,"baseGrowth")+value(data,"careGrowth")+value(data,"activityBonus")+max(0l,value(data,"xp")-value(data,"petXpBaseline"));}
    function ageDays(data,now){return (max(0l,now-value(data,"birthEpoch"))/86400).toNumber();}
    function oldStage(x,age){
        if(x>=300000 && age>=21){return 5;}if(x>=150000 && age>=14){return 4;}
        if(x>=70000 && age>=7){return 3;}if(x>=20000 && age>=2){return 2;}return x>=2000?1:0;
    }
    function hatchDurationHours(data){
        var bonus=min(16,max(value(data,"activityBonus"),max(0l,value(data,"xp")-value(data,"petXpBaseline")))/1000.0+value(data,"careGrowth")/(max(1,value(data,"careCap"))/16.0));
        return max(value(data,"hatchMinimum"),value(data,"hatchHours")-bonus);
    }
    function stage(data,now){
        var total=growth(data);var age=ageDays(data,now);var floor=value(data,"stageFloor");
        var s=oldStage(total,age);
        if(s==1 && floor==0){s=max(0l,now-value(data,"birthEpoch"))/3600.0>=hatchDurationHours(data)?1:0;}
        if(s==0 && now-value(data,"birthEpoch")>=value(data,"hatchHours")*3600){s=1;}
        if(total>=300000 && age>=value(data,"legendDays")){s=5;}
        if(s==5 && age<value(data,"legendDays")){s=4;}
        return max(floor,s);
    }
    function nextSteps(stage){return [12000,20000,70000,150000,300000,325000][stage];}
    function nextAge(data,stage){return [1,2,7,14,value(data,"legendDays"),0][stage];}
    function mastery(data,stage){return stage<5?0:1+max(0l,(growth(data)-300000)/25000);}
    function masteryProgress(data){return max(0l,growth(data)-300000)%25000;}
    function progress(data,now,stage){
        if(stage==5){return masteryProgress(data)/25000.0;}
        if(stage==0){return min(1.0,max(0l,now-value(data,"birthEpoch"))/(hatchDurationHours(data)*3600.0));}
        var previous=[0,2000,20000,70000,150000][stage];
        return min(1.0,max(0l,growth(data)-previous)/(nextSteps(stage)-previous).toFloat());
    }
    // The sole mutator here: only passive-growth fields, never XP or rewards.
    function advance(data,now){
        var elapsed=max(0l,now-value(data,"lastGrowth"));
        if(elapsed>0){var units=elapsed*value(data,"passiveRate")+value(data,"growthRemainder");
            data["baseGrowth"]+=units/86400;data["growthRemainder"]=units%86400;data["lastGrowth"]=now;}
    }
    // Selection is read-only; the orchestrator decides when to persist it.
    function chooseFamily(data){
        var p=data["personality"];var scores=[p[0],p[1],p[2],p[3]];
        var big=0;var steady=0;var moderate=0;var easy=0;
        for(var i=0;i<32;i++){if(data["days"][i]==0){continue;}var n=data["counts"][i];
            if(n>=18000){big++;}if(n>=6000){steady++;}if(n>=3000){moderate++;}else{easy++;}}
        if(big>=2){scores[1]+=8;}if(steady>=5){scores[0]+=8;}if(moderate>=3 && easy>=1){scores[2]+=8;}
        var winner=((value(data,"birthEpoch")%4+value(data,"petSerial"))%4).toNumber();
        for(var i=0;i<4;i++){if(scores[i]>scores[winner]){winner=i;}}
        return winner+1;
    }
}
