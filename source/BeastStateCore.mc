// Background-safe orchestration; foreground interactions extend this core.
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Lang;
using Toybox.UserProfile;

(:background)
class BeastStateCore {
    var store; var data=null; var dev=false;
    var testNow=null; var skipWatch=false;
    function initialize(){store=new BeastStore();}
    function max(a,b){return a>b?a:b;}
    function min(a,b){return a<b?a:b;}
    function clamp(x){return min(100,max(0,x));}
    function realNow(){return testNow==null?Time.now().value().toLong():testNow;}
    function now(){return realNow();}
    function dateKey(moment){var d=Gregorian.info(moment,Time.FORMAT_SHORT);return d.year*10000+d.month*100+d.day;}
    function today(){return dateKey(new Time.Moment(now().toNumber()));}
    function legacy(key){var v=store.read(key);return v==null?0:v;}
    function number(key){return data.hasKey(key)?data[key]:0;}
    function start(){
        if(data!=null){return;}
        // Garmin returns a deserialized value; only the RAM backend aliases its
        // stored document. Keep the independent dirty baseline, avoid a third
        // full-pet copy in the constrained background VM.
        var saved=store.read("v4");data=store.memory==null?saved:store.copy(saved);if(data!=null){
            if(!data.hasKey("equipped")){data["equipped"]=-1;}
            if(!data.hasKey("activityBonus")){data["activityBonus"]=0l;}
            if(!data.hasKey("activityUnitGrowth")){data["activityUnitGrowth"]=1000;}
            if(!data.hasKey("discoveryMask")){data["discoveryMask"]=0;for(var i=0;i<8;i++){if(data["items"][i]>0){data["discoveryMask"]|=1<<i;}}}
            migrateV5();
            return;
        }
        var exists=store.read("birth")!=null;
        var epoch=store.read("birthEpoch");
        if(epoch==null){
            epoch=now();
            if(exists){
                // Very early saves have a local birth date but no epoch. Recover
                // calendar age instead of making an older beast newborn again.
                try{var days=(calendarMoment(today())-calendarMoment(legacy("birth")))/86400;epoch-=max(0l,days)*86400;}
                catch(e instanceof Lang.Exception){}
            }
        }
        data={"version"=>4,"birth"=>exists?legacy("birth"):today(),"birthEpoch"=>epoch.toLong(),
            "birthBaseline"=>exists?legacy("birthBaseline"):(skipWatch?0:getTodaySteps()),
            "xp"=>exists?legacy("xp").toLong():0l,"snacks"=>exists?legacy("snacks"):0,
            "snackRemainder"=>exists?legacy("snackRemainder"):0,"friendship"=>exists?legacy("friendship"):0,
            "patDay"=>exists?legacy("patDay"):0,"pats"=>exists?legacy("pats"):0,"family"=>exists?legacy("family"):0,
            "baseGrowth"=>0l,"careGrowth"=>0l,"activityBonus"=>0l,"activityUnitGrowth"=>1000,"discoveryMask"=>0,"growthRemainder"=>0l,"petXpBaseline"=>0l,
            "lastGrowth"=>now(),"lastCare"=>now(),"stageFloor"=>0,"evolutionPending"=>0,
            "fullness"=>75,"happiness"=>65,"energy"=>80,"cleanliness"=>100,
            "poop"=>0,"poopDue"=>0l,"lastPoop"=>0l,"sleepUntil"=>0l,
            "day"=>today(),"meals"=>2,"games"=>0,"careToday"=>0,"rested"=>0,
            "activityMilestone"=>0,"adventure"=>0,"encounters"=>0,"target"=>2000,
            "minutesBase"=>-1,"pushBase"=>-1,"sound"=>0,"haptics"=>1,"motion"=>2,
            "passiveRate"=>12000,"careCap"=>300,"hatchHours"=>24,"hatchMinimum"=>8,"legendDays"=>21,
            "forcedStage"=>-1,"forcedFamily"=>0,"personality"=>[0,0,0,0],
            "collection"=>0,"rareCollection"=>0,"charms"=>0,"rare"=>0,"petSerial"=>0,
            "items"=>[0,0,0,0,0,0,0,0],"equipped"=>-1,"days"=>[],"counts"=>[]};
        for(var i=0;i<32;i++){data["days"].add(exists?legacy("day"+i):0);data["counts"].add(exists?legacy("count"+i):0);}
        // Capture existing stages before changing the hatch rule. No retroactive
        // passive XP, no reset of legacy keys, and a retained migration snapshot.
        if(exists){data["stageFloor"]=oldStage(xp(),ageDays());if(number("family")>0){data["stageFloor"]=max(3,number("stageFloor"));}}
        migrateV5();store.write("v4.migration",store.copy(data));commit();
    }
    function migrateV5(){
        // Additive migration: canonical key/version and all existing values stay
        // intact. A single atomic document also owns resumable game transactions.
        var defaults={"sleepMode"=>0,"bedMinute"=>1320,"wakeMinute"=>420,"watchBed"=>1320,"watchWake"=>420,
            "nextBed"=>0l,"nextWake"=>0l,"scheduleAt"=>0l,"sleepSource"=>"FALLBACK","autoLights"=>1,"lights"=>0,"lightsUntil"=>0l,"vibeStyle"=>0,
            "gameSerial"=>0,"gameDone"=>0,"session"=>null,"sessions"=>[null,null,null],"gameClaims"=>[0,0,0],"easy"=>0,"v5"=>1,"profileZone"=>null,
            "awakeAt"=>0l,"awakeUntil"=>0l,"awakeZone"=>null,"grumpAt"=>0l,"grumpLevel"=>0,
            "poopSlots"=>0,"lastCleanReward"=>0l};
        var keys=defaults.keys();for(var i=0;i<keys.size();i++){if(!data.hasKey(keys[i])){data[keys[i]]=defaults[keys[i]];}}
        // Freeze an already-adult legacy branch before introducing new tendencies.
        if(!data.hasKey("affinity")){
            if(number("family")==0 && stage()>=3){data["family"]=BeastProgression.chooseFamily(data);}
            data["affinity"]=[0,0,0,0];data["affinityToday"]=[0,0,0,0];data["affinityDay"]=number("day");
            data["temperament"]=BeastAffinity.temperament(number("birthEpoch"),number("petSerial"));
        }
        if(!data.hasKey("careDifficulty")){
            data["careDifficulty"]=1;data["careAt"]=max(now(),number("lastCare"));
            data["foodRemainder"]=0;data["joyRemainder"]=0;
            data["careStepDay"]=number("day");data["careStepUnits"]=min(5,BeastActivityRules.credited(data,number("day"))/2000);
            data["digestion"]=[0l,0,0l,0,0l,0,0l,0];data["digestRemainder"]=0;
            data["digestDay"]=number("day");data["digestWaste"]=0;
        }
        repairPoop();
        // Old saves without a pending meal start a new interval, not retroactive
        // waste for time before this feature existed. Keep an already-due meal.
        if(number("poopDue")==0){data["poopDue"]=max(now(),number("lastPoop"))+BeastCareRules.interval(data);}
    }
    function poopMask(){
        var mask=number("poopSlots")&31;var count=0;
        for(var i=0;i<5;i++){if((mask&(1<<i))!=0){count++;}}
        var wanted=min(5,max(0,number("poop")));
        return count==wanted?mask:(1<<wanted)-1;
    }
    function repairPoop(){data["poop"]=min(5,max(0,number("poop")));data["poopSlots"]=poopMask();}
    function advancePoop(t){repairPoop();BeastCareRules.waste(data,t,today());}

    function refreshSleep(){
        if(dev || skipWatch || number("sleepMode")!=0){return;}
        data["nextBed"]=0l;data["nextWake"]=0l;data["scheduleAt"]=now();data["sleepSource"]="FALLBACK";
        data["profileZone"]=BeastSleep.zoneAt(now());
        data["watchBed"]=number("bedMinute");data["watchWake"]=number("wakeMinute");
        try{
            var p=UserProfile.getProfile();
            if(p!=null){
                if(p.sleepTime!=null && p.wakeTime!=null){
                    var bed=p.sleepTime.value()/60;var wake=p.wakeTime.value()/60;
                    if(BeastSleep.validSchedule(bed,wake)){data["watchBed"]=bed;data["watchWake"]=wake;data["sleepSource"]="WATCH TYPICAL";}
                }
                if((p has :upcomingSleepTime) && (p has :upcomingWakeTime) && p.upcomingSleepTime!=null && p.upcomingWakeTime!=null){
                    var b=p.upcomingSleepTime.value().toLong();var w=p.upcomingWakeTime.value().toLong();
                    if(b!=w && b>now() && w>now() && b-now()<=172800 && w-now()<=172800){
                        data["nextBed"]=b;data["nextWake"]=w;data["sleepSource"]="WATCH UPCOMING";
                    }
                }
            }
        }catch(e instanceof Lang.Exception){data["sleepSource"]="FALLBACK";}
    }
    function refreshSleepCached(){
        // Profile data is not a continuously changing sensor. Explicit Settings,
        // opening the app, and native sleep/wake events still force a refresh.
        if(number("sleepMode")==0 && (number("scheduleAt")==0 || now()<number("scheduleAt") || now()-number("scheduleAt")>=900 || number("profileZone")!=BeastSleep.zoneAt(now()))){refreshSleep();}
    }
    function isNight(){return BeastSleep.night(data,now());}
    function isSleeping(){return BeastSleep.sleeping(data,now());}
    function grump(){return BeastSleep.grump(data,now());}
    function happiness(){return BeastSleep.happiness(data,now());}

    function calendarMoment(key){
        return Gregorian.moment({:year=>(key/10000).toNumber(),:month=>((key/100)%100).toNumber(),:day=>key%100,:hour=>0,:minute=>0,:second=>0}).value().toLong();
    }
    function commit(){if(!dev){
        data["cachedName"]=speciesName();data["cachedMood"]=mood();data["cachedProgress"]=progress();
        var s=stage();data["cachedSprite"]=s<3?s:3+(family()-1)*3+s-3;
        store.savePet(data);
        // Never load the large inventory/history/session document in a 32KB
        // Glance VM. This optional read-only cache does not own pet progress.
        var summary={};var fields=["careDifficulty","careAt","foodRemainder","joyRemainder","cleanliness","cachedName","cachedProgress","cachedSprite","poop","energy","fullness","happiness","friendship","lastCare","sleepMode","nextBed","nextWake","scheduleAt","watchBed","watchWake","bedMinute","wakeMinute","sleepUntil","awakeAt","awakeUntil","awakeZone","grumpAt","grumpLevel"];
        for(var i=0;i<fields.size();i++){summary[fields[i]]=data[fields[i]];}
        store.writeGlance(summary);}}
    function xp(){return number("xp");} // genuine lifetime watch steps ONLY
    function growth(){return BeastProgression.growth(data);}
    function ageDays(){return BeastProgression.ageDays(data,now());}
    function oldStage(x,a){return BeastProgression.oldStage(x,a);}
    function stage(){
        if(dev && number("forcedStage")>=0){return number("forcedStage");}
        return BeastProgression.stage(data,now());
    }
    function hatchDurationHours(){
        return BeastProgression.hatchDurationHours(data);
    }
    function mastery(){return BeastProgression.mastery(data,stage());}
    function masteryProgress(){return BeastProgression.masteryProgress(data);}
    function nextSteps(){return BeastProgression.nextSteps(stage());}
    function nextAge(){return BeastProgression.nextAge(data,stage());}
    function progress(){
        return BeastProgression.progress(data,now(),stage());
    }
    function tick(){
        start();var t=now();BeastProgression.advance(data,t);
        var day=today();
        // Persisted high-water local day prevents rollback reward refills.
        if(day>number("day")){data["day"]=day;data["meals"]=2;data["games"]=0;data["careToday"]=0;
            data["rested"]=0;data["activityMilestone"]=0;data["minutesBase"]=0;data["pushBase"]=0;}
        var care=max(0l,t-number("lastCare"));
        if(care>=3600){
            var h=min(24,care/3600).toNumber();var old=(number("lastCare")/3600).toNumber();
            data["energy"]=min(100,number("energy")+5*((old+h)/4-old/4));
            for(var hour=0;hour<h && number("energy")<100;hour++){
                var at=number("lastCare")+hour*3600+1800;
                if(BeastSleep.sleeping(data,at)){data["energy"]=min(100,number("energy")+8);}
            }
            data["lastCare"]=care>86400?t:number("lastCare")+h*3600;
        }
        BeastCareRules.advance(data,t,false);advancePoop(t);
        var prior=number("stageFloor");var s=stage();data["stageFloor"]=max(prior,s);
        if(s>prior && !(dev && number("forcedStage")>=0)){data["evolutionPending"]=1;}
        if(s>=3){family();}if(s==5){var flag=1<<(family()-1);
            if((number("collection")&flag)==0){data["collection"]|=flag;data["charms"]++;}}
    }
    // Watermark + XP + inventory saved in one atomic document, never separately.
    function observe(day,total){
        start();if(dev){return;}BeastActivityRules.observe(data,day,total);
        if(day==today()){BeastCareRules.activity(data,day,BeastActivityRules.credited(data,day));}
    }

    function syncActivity(steps,minutes,pushes){
        start();refreshSleepCached();tick();
        if(!dev && !skipWatch){if(steps!=null){observe(today(),steps);}
            activityRewards(today(),steps,minutes,pushes);}
        tick();commit();
    }

    function stepNoop(steps,minutes,pushes){
        // Never throttle NEW steps, new reward thresholds, date/care/poop
        // boundaries, or sleep/wake callbacks. Only duplicate step events may
        // defer sub-minute passive-only catch-up, which remains exactly lazy.
        var t=now();var day=today();
        if(steps==null || steps<0 || day!=number("day") || t<number("lastGrowth") || t-number("lastGrowth")>=60 || t-number("lastCare")>=3600){return false;}
        if(number("poopDue")>0 && t>=number("poopDue")){return false;}
        if(number("sleepMode")==0 && (number("scheduleAt")==0 || t<number("scheduleAt") || t-number("scheduleAt")>=900)){return false;}
        var eligible=BeastActivityRules.eligible(data,day,steps);
        var prior=BeastActivityRules.credited(data,day);if(eligible>prior){return false;}
        var n=prior/max(1,number("target"));
        if(minutes!=null){if(number("minutesBase")<0){return false;}n=max(n,max(0,minutes-number("minutesBase"))/10);}
        if(pushes!=null){if(number("pushBase")<0){return false;}n=max(n,max(0,pushes-number("pushBase"))/500);}
        return min(5,n)<=number("activityMilestone");
    }
    function activityRewards(day,steps,minutes,pushes){
        if(dev){return;}BeastActivityRules.rewards(data,day,steps,minutes,pushes);
    }
    function family(){
        if(dev && number("forcedFamily")>0){return number("forcedFamily");}if(stage()<3){return 0;}
        if(number("family")!=0){return number("family");}
        data["family"]=BeastProgression.chooseFamily(data);return number("family");
    }

    function speciesName(){
        var s=stage();if(s<3){return ["MYSTERY EGG","PIP","NIMBLE"][s];}
        if(number("rare")!=0){return ["LUMENHART","ASHEN PHOENIX","MOONWATER KIRIN","ECLIPSE EIDOLON"][family()-1];}
        return [["MOSSBIT","CINDERCUB","PUDDLEFIN","FLICKLET"],["THORNBUCK","PYROLYNX","CURRENTAIL","NOCTURNE"],
            ["VERDANT ELDER","SOLFLARE","LEVIATHAN","STARWEAVER"]][s-3][family()-1];
    }
    function getTodaySteps(){return GarminActivity.todaySteps();}
    function friendship(){return number("friendship");}function snacks(){return number("snacks");}

    function mood(){
        return BeastSleep.mood(data,now());
    }

}
