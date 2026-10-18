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
    function sleeping(data,epoch){return night(data,epoch) || value(data,"sleepUntil",0l)>epoch;}
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
        return moodValues(data,epoch,value(data,"energy",80),value(data,"fullness",75),value(data,"happiness",65));
    }
    function careHours(data,epoch){
        var last=value(data,"lastCare",0l);if(last<=0 || epoch<last){return 0;}
        var h=((epoch-last)/3600).toNumber();return h>24?24:h;
    }
    function forecastEnergy(data,epoch){
        var energy=value(data,"energy",80);var h=careHours(data,epoch);var last=value(data,"lastCare",0l);
        var old=(last/3600).toNumber();energy+=5*((old+h)/4-old/4);
        for(var hour=0;hour<h;hour++){if(sleeping(data,last+hour*3600+1800)){energy+=8;}}
        return energy>100?100:energy;
    }
    // Pure lazy-care projection for a cached Glance. It neither writes nor
    // advances growth and avoids stale SLEEPY after an unobserved night's rest.
    function previewMood(data,epoch){
        var h=careHours(data,epoch);var old=(value(data,"lastCare",0l)/3600).toNumber();
        var food=value(data,"fullness",75)-3*((old+h)/6-old/6);if(food<30){food=30;}
        var joy=value(data,"happiness",65)-2*((old+h)/8-old/8);if(joy<40){joy=40;}
        return moodValues(data,epoch,forecastEnergy(data,epoch),food,joy);
    }
    function moodValues(data,epoch,energy,food,joy){
        if(night(data,epoch)){return "ASLEEP";}
        if(value(data,"sleepUntil",0l)>epoch){return "RESTING";}
        if(energy<20){return "SLEEPY";}
        if(value(data,"poop",0)>0){return "MESSY";}
        if(food<45){return "HUNGRY";}
        if(joy<50){return "LONELY";}
        if(joy>=85){return "EXCITED";}
        if(joy>=70){return "PLAYFUL";}
        return value(data,"friendship",0)>=25?"CONTENT":"COZY";
    }
}
