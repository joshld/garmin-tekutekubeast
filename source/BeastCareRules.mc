// Portable lazy care: seconds and local day supplied by State, never sensors.
(:background,:glance)
module BeastCareRules {
    function value(d,k,f){return d.hasKey(k)?d[k]:f;}
    function min(a,b){return a<b?a:b;}
    function max(a,b){return a>b?a:b;}
    function mode(d){return max(0,min(2,value(d,"careDifficulty",1)));}
    function foodRate(d){var m=mode(d);return m==0?6:(m==1?20:30);}
    function joyRate(d){var m=mode(d);return m==0?4:(m==1?12:20);}
    function interval(d){var m=mode(d);return m==0?86400:(m==1?57600:43200);}
    function delay(d){return (4-mode(d))*3600;}
    function elapsed(d,t){return min(259200l,max(0l,t-value(d,"careAt",t)));}
    function projected(d,t,food){
        var key=food?"fullness":"happiness";var remainder=food?"foodRemainder":"joyRemainder";
        var loss=(elapsed(d,t)*(food?foodRate(d):joyRate(d))+value(d,remainder,0))/86400;
        var current=value(d,key,food?75:65);return max(min(food?10:15,current),current-loss).toNumber();
    }
    function advance(d,t,force){
        var last=d["careAt"];if(t<=last || (!force && t-last<3600)){return;}
        var at=force || t-last>259200?t:last+((t-last)/3600).toLong()*3600;
        var seconds=elapsed(d,at);
        var food=seconds*foodRate(d)+d["foodRemainder"];
        var joy=seconds*joyRate(d)+d["joyRemainder"];
        d["fullness"]=max(min(10,d["fullness"]),d["fullness"]-food/86400).toNumber();
        d["happiness"]=max(min(15,d["happiness"]),d["happiness"]-joy/86400).toNumber();
        // Advance through all absent time; reopening cannot replay capped decay.
        d["foodRemainder"]=(food%86400).toNumber();d["joyRemainder"]=(joy%86400).toNumber();d["careAt"]=at;
    }
    function activity(d,day,credited){
        if(day<d["careStepDay"]){return;}
        if(day>d["careStepDay"]){d["careStepDay"]=day;d["careStepUnits"]=0;}
        var units=min(5,credited/2000).toNumber();var old=d["careStepUnits"];
        if(units<=old){return;}
        var m=mode(d);var foodCap=m==0?3:(m==1?5:8);var foodUnit=m==2?2:1;
        var energyCap=m==0?2:(m==1?4:5);
        d["fullness"]=max(min(10,d["fullness"]),d["fullness"]-min(foodCap,units*foodUnit)+min(foodCap,old*foodUnit));
        d["energy"]=max(0,d["energy"]-min(energyCap,units)+min(energyCap,old));
        d["happiness"]=min(100,d["happiness"]+units/2-old/2);
        d["careStepUnits"]=units;
    }
    function addWaste(d,count){
        var added=min(5-d["poop"],count).toNumber();var left=added;var mask=d["poopSlots"];
        for(var slot=0;slot<5 && left>0;slot++){
            if((mask&(1<<slot))==0){mask|=1<<slot;left--;}
        }
        d["poop"]+=added;d["poopSlots"]=mask;d["cleanliness"]=max(0,d["cleanliness"]-15*added);
    }
    function waste(d,t,day){
        // Rollback cannot advance digestion, reset caps or create waste.
        if(t<d["careAt"]){return;}
        var due=d["poopDue"];var period=interval(d);
        if(due>0 && t>=due){
            var events=((t-due)/period).toLong()+1;addWaste(d,events);
            d["lastPoop"]=due+(events-1)*period;d["poopDue"]=d["lastPoop"]+period;
        }
        if(day>d["digestDay"]){d["digestDay"]=day;d["digestWaste"]=0;}
        var queue=d["digestion"];var units=d["digestRemainder"];
        for(var i=0;i<8;i+=2){
            if(queue[i]>0 && t>=queue[i]){units+=queue[i+1];queue[i]=0l;queue[i+1]=0;}
        }
        var count=min(max(0,mode(d)+1-d["digestWaste"]),units/3).toNumber();
        if(day>=d["digestDay"]){addWaste(d,count);d["digestWaste"]+=count;}
        // Excess at capacity/daily cap is consumed, never a hidden backlog.
        d["digestRemainder"]=units%3;
    }
    function feed(d,t,meal){
        var queue=d["digestion"];var due=max(t,d["careAt"])+delay(d);var units=meal?2:1;
        var total=0;var free=-1;var same=-1;
        for(var i=0;i<8;i+=2){total+=queue[i+1];if(queue[i]==due){same=i;}if(queue[i]==0 && free<0){free=i;}}
        units=min(units,8-total);if(units<=0){return;}
        var index=same>=0?same:free;if(index<0){return;}
        queue[index]=due;queue[index+1]+=units;
    }
}
