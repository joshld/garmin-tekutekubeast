// Deterministic ledger/rewards. Day is an explicit local YYYYMMDD key; inputs
// are cumulative genuine activity counters, never generated game movement.
(:background)
module BeastActivityRules {
    function number(data,key){return data.hasKey(key)?data[key]:0;}
    function max(a,b){return a>b?a:b;}
    function min(a,b){return a<b?a:b;}
    function eligible(data,day,total){return max(0,total-(day==number(data,"birth")?number(data,"birthBaseline"):0));}
    function credited(data,day){var slot=day%32;return data["days"][slot]==day?data["counts"][slot]:0;}
    function observe(data,day,total){
        if(day<number(data,"birth") || total<0){return;}
        var count=eligible(data,day,total);var previous=credited(data,day);
        if(count<=previous){return;}
        var slot=day%32;data["days"][slot]=day;data["counts"][slot]=count;
        var delta=count-previous;data["xp"]+=delta;
        var food=number(data,"snackRemainder")+delta;
        data["snacks"]=min(12,number(data,"snacks")+food/2500);data["snackRemainder"]=food%2500;
    }
    function rewards(data,day,steps,minutes,pushes){
        if(day!=number(data,"day")){return;}var n=0;
        if(steps!=null){n=credited(data,day)/number(data,"target");}
        if(minutes!=null){if(number(data,"minutesBase")<0){data["minutesBase"]=minutes;}n=max(n,max(0,minutes-number(data,"minutesBase"))/10);}
        if(pushes!=null){if(number(data,"pushBase")<0){data["pushBase"]=pushes;}n=max(n,max(0,pushes-number(data,"pushBase"))/500);}
        // Multiple measurements of the same effort only earn once.
        n=min(5,n);if(n>number(data,"activityMilestone")){
            var delta=n-number(data,"activityMilestone");data["adventure"]+=delta;
            data["activityBonus"]=number(data,"activityBonus")+delta*number(data,"activityUnitGrowth");data["activityMilestone"]=n;}
    }
}
