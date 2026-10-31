using Toybox.Time;
using Toybox.Time.Gregorian;

// Pure/read-only rules shared by foreground, background and the small Glance VM.
(:background, :glance)
module BeastSleep {
    function value(data,key,fallback){return data.hasKey(key)?data[key]:fallback;}
    function minuteAt(epoch){var d=Gregorian.info(new Time.Moment(epoch.toNumber()),Time.FORMAT_SHORT);return d.hour*60+d.min;}
    function zoneAt(epoch){
        var d=Gregorian.info(new Time.Moment(epoch.toNumber()),Time.FORMAT_SHORT);
        return Gregorian.moment({:year=>d.year,:month=>d.month,:day=>d.day,:hour=>d.hour,:minute=>d.min,:second=>d.sec}).value().toLong()-epoch;
    }
    function inWindow(minute,bed,wake){return bed==wake?false:(bed<wake?(minute>=bed && minute<wake):(minute>=bed || minute<wake));}
    function validSchedule(bed,wake){return bed>=0 && bed<1440 && wake>=0 && wake<1440 && bed!=wake;}
    function night(data,epoch){
        var mode=value(data,"sleepMode",0);if(mode==2){return false;}
        if(mode==0){
            var bed=value(data,"nextBed",0l);var wake=value(data,"nextWake",0l);
            // API 6 upcoming moments can straddle different dates. The earlier
            // forthcoming event identifies current state, but never use stale
            // moments after an event, timezone change or an accelerated DEV jump.
            if(epoch>=value(data,"scheduleAt",0l) && bed>0 && wake>0 && bed-epoch<=172800 && wake-epoch<=172800){
                if(bed<wake && epoch<wake){return epoch>=bed;}
                if(wake<bed && epoch<bed){return epoch<wake;}
            }
        }
        return inWindow(minuteAt(epoch),value(data,mode==0?"watchBed":"bedMinute",1320),value(data,mode==0?"watchWake":"wakeMinute",420));
    }
    function awake(data,epoch){
        var at=value(data,"awakeAt",0l);var until=value(data,"awakeUntil",0l);
        return at>0 && epoch>=at && epoch<until && until-at<=86400 && value(data,"awakeZone",null)==zoneAt(epoch);
    }
    function sleeping(data,epoch){var nap=value(data,"sleepUntil",0l)-epoch;return !awake(data,epoch) && (night(data,epoch) || (nap>0 && nap<=3600));}
    function scheduleEnd(data,epoch){
        var next=value(data,"nextWake",0l);
        if(value(data,"sleepMode",0)==0 && next>epoch && next-epoch<=86400){return next;}
        var d=Gregorian.info(new Time.Moment(epoch.toNumber()),Time.FORMAT_SHORT);
        var wake=value(data,value(data,"sleepMode",0)==0?"watchWake":"wakeMinute",420);
        var minutes=(wake-d.hour*60-d.min+1440)%1440;if(minutes==0){minutes=1440;}
        return epoch-d.sec+minutes*60;
    }
    function napAnnoyance(elapsed){
        // Compact bell, peak at 17.5 min; zero at <=5 and >=30 minutes.
        if(elapsed<=300 || elapsed>=1800){return 0;}
        var distance=(elapsed-1050)/750.0;var curve=1-distance*distance;
        return (2*curve*curve+0.5).toNumber();
    }
    function wakeAnnoyance(data,epoch){
        if(!sleeping(data,epoch)){return 0;}
        if(!night(data,epoch)){return napAnnoyance(epoch-(value(data,"sleepUntil",0l)-3600));}
        // Night sleep is not a one-hour nap: at most one point, none close
        // to scheduled waking or immediately after typical bedtime.
        var bed=value(data,value(data,"sleepMode",0)==0?"watchBed":"bedMinute",1320);
        var elapsed=(minuteAt(epoch)-bed+1440)%1440;
        return elapsed<5 || scheduleEnd(data,epoch)-epoch<=900?0:1;
    }
    function grump(data,epoch){
        var at=value(data,"grumpAt",0l);var level=value(data,"grumpLevel",0);
        var elapsed=epoch-at;var duration=level==2?300:120;
        if(at<=0 || elapsed<0 || elapsed>=duration){return 0;}
        return level==2 && elapsed>=150?1:level;
    }
    function happiness(data,epoch){var n=value(data,"happiness",65)-grump(data,epoch);return n<0?0:n;}
    // Existing save keys: lights=0 ON / 1 OFF, lightsUntil is absolute expiry.
    // A clock rollback must not turn a one-hour override into a multi-day one.
    function lightingMode(data,epoch){
        var remaining=value(data,"lightsUntil",0l)-epoch;
        if(remaining>0 && remaining<=3600){return value(data,"lights",0)==1?2:1;}
        return 0; // AUTO; expiry is lazy/read-only, never a background save write.
    }
    function lightingMinutes(data,epoch){
        return lightingMode(data,epoch)==0?0:((value(data,"lightsUntil",0l)-epoch+59)/60).toNumber();
    }
    function dark(data,epoch){
        var mode=lightingMode(data,epoch);if(mode!=0){return mode==2;}
        return value(data,"autoLights",1)==1 && night(data,epoch);
    }
    function mood(data,epoch){
        return moodValues(data,epoch,value(data,"energy",80),value(data,"fullness",75),happiness(data,epoch));
    }
    function careHours(data,epoch){
        var last=value(data,"lastCare",0l);if(last<=0 || epoch<last){return 0;}
        var h=((epoch-last)/3600).toNumber();return h>24?24:h;
    }
    function forecastEnergy(data,epoch){
        var energy=value(data,"energy",80);var h=careHours(data,epoch);var last=value(data,"lastCare",0l);
        var old=(last/3600).toNumber();energy+=5*((old+h)/4-old/4);
        for(var hour=0;hour<h && energy<100;hour++){if(sleeping(data,last+hour*3600+1800)){energy+=8;}}
        return energy>100?100:energy;
    }
    // Pure lazy-care projection for a cached Glance. It neither writes nor
    // advances growth and avoids stale SLEEPY after an unobserved night's rest.
    function previewMood(data,epoch){
        var food=BeastCareRules.projected(data,epoch,true);
        var joy=BeastCareRules.projected(data,epoch,false)-grump(data,epoch);
        return moodValues(data,epoch,forecastEnergy(data,epoch),food,joy);
    }
    function moodValues(data,epoch,energy,food,joy){
        if(sleeping(data,epoch)){return night(data,epoch)?"ASLEEP":"RESTING";}
        if(grump(data,epoch)>0){return "GRUMPY";}
        if(energy<20){return "SLEEPY";}
        if(food<30){return "HUNGRY";}
        if(value(data,"poop",0)>0 || value(data,"cleanliness",100)<45){return "MESSY";}
        if(food<45){return "HUNGRY";}
        if(joy<50){return "LONELY";}
        if(joy>=85){return "EXCITED";}
        if(joy>=70){return "PLAYFUL";}
        return value(data,"friendship",0)>=25?"CONTENT":"COZY";
    }
}
