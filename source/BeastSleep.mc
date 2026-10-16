using Toybox.Time;
using Toybox.Time.Gregorian;

// Pure/read-only rules shared by foreground, background and the small Glance VM.
(:background, :glance)
module BeastSleep {
    function value(data,key,fallback){return data.hasKey(key)?data[key]:fallback;}
    function minuteAt(epoch){var d=Gregorian.info(new Time.Moment(epoch.toNumber()),Time.FORMAT_SHORT);return d.hour*60+d.min;}
    function inWindow(minute,bed,wake){return bed==wake?false:(bed<wake?(minute>=bed && minute<wake):(minute>=bed || minute<wake));}
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
    function dark(data,epoch){
        if(value(data,"lightsUntil",0l)>epoch){return value(data,"lights",0)==1;}
        return value(data,"autoLights",1)==1 && night(data,epoch);
    }
    function mood(data,epoch){
        if(night(data,epoch)){return "ASLEEP";}
        if(value(data,"sleepUntil",0l)>epoch){return "RESTING";}
        if(value(data,"energy",80)<20){return "SLEEPY";}
        if(value(data,"poop",0)>0){return "MESSY";}
        if(value(data,"fullness",75)<45){return "HUNGRY";}
        if(value(data,"happiness",65)<50){return "LONELY";}
        if(value(data,"happiness",65)>=85){return "EXCITED";}
        if(value(data,"happiness",65)>=70){return "PLAYFUL";}
        return value(data,"friendship",0)>=25?"CONTENT":"COZY";
    }
}
