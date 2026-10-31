// Portable family tendencies: ordinary care and activity do not enter these scores.
(:background)
module BeastAffinity {
    function mod(value, divisor){
        var result=(value%divisor).toNumber();
        return result<0?result+divisor:result;
    }
    function field(data,key){return data.hasKey(key)?data[key]:0;}
    function temperament(epoch,serial){
        // Small bounded arithmetic is reproducible on Garmin, JavaScript and C/C++.
        var seed=(mod(epoch,65521)*17+mod(serial,65521)*719+11)%65521;
        return mod(seed,4)+1;
    }
    function credit(data,family,points,day){
        if(family<1 || family>4 || points<=0 || day<data["affinityDay"]){return 0;}
        if(day>data["affinityDay"]){
            data["affinityDay"]=day;data["affinityToday"]=[0,0,0,0];
        }
        var index=family-1;var available=6-data["affinityToday"][index];
        var credited=points<available?points:available;
        if(credited<=0){return 0;}
        data["affinity"][index]+=credited;data["affinityToday"][index]+=credited;
        return credited;
    }
    function score(data,index,innate){
        var points=data.hasKey("affinity")?data["affinity"][index]:0;
        return points+(innate==index+1?2:0);
    }
    function choose(data){
        var innate=field(data,"temperament");
        if(innate<1 || innate>4){innate=temperament(field(data,"birthEpoch"),field(data,"petSerial"));}
        var highest=score(data,0,innate);var count=1;
        for(var i=1;i<4;i++){
            var points=score(data,i,innate);
            if(points>highest){highest=points;count=1;}
            else if(points==highest){count++;}
        }
        // Pick among the actual tied maxima; do not start a scan at a random family.
        var rank=(mod(field(data,"birthEpoch"),count)+mod(field(data,"petSerial"),count))%count;
        for(var i=0;i<4;i++){
            if(score(data,i,innate)==highest){
                if(rank==0){return i+1;}rank--;
            }
        }
        return innate;
    }
    function hint(data){
        var family=choose(data);
        if(family==1){return "Growing gentle";}
        if(family==2){return "Growing bold";}
        if(family==3){return "Growing calm";}
        return "Growing curious";
    }
}