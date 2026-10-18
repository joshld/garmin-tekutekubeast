using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Lang;
using Toybox.UserProfile;

(:background)
class TekuTekuBeastState {
    var store; var data=null; var dev=false;
    var virtualNow=0l; var anchor=0l; var speed=1;
    var testNow=null; var skipWatch=false;
    function initialize(){store=new BeastStore();}
    function max(a,b){return a>b?a:b;}
    function min(a,b){return a<b?a:b;}
    function clamp(x){return min(100,max(0,x));}
    function realNow(){return testNow==null?Time.now().value().toLong():testNow;}
    function now(){return dev?virtualNow+max(0l,realNow()-anchor)*speed:realNow();}
    function dateKey(moment){var d=Gregorian.info(moment,Time.FORMAT_SHORT);return d.year*10000+d.month*100+d.day;}
    function today(){return dateKey(new Time.Moment(now().toNumber()));}
    function legacy(key){var v=store.read(key);return v==null?0:v;}
    function number(key){return data.hasKey(key)?data[key]:0;}
    function start(){
        if(data!=null){return;}
        data=store.copy(store.read("v4"));if(data!=null){
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
            "gameSerial"=>0,"gameDone"=>0,"session"=>null,"sessions"=>[null,null,null],"gameClaims"=>[0,0,0],"easy"=>0,"v5"=>1,"profileZone"=>null};
        var keys=defaults.keys();for(var i=0;i<keys.size();i++){if(!data.hasKey(keys[i])){data[keys[i]]=defaults[keys[i]];}}
    }
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
    function isDark(){return BeastSleep.dark(data,now());}
    function toggleLights(){data["lights"]=isDark()?0:1;data["lightsUntil"]=now()+3600;commit();}
    function calendarMoment(key){
        return Gregorian.moment({:year=>(key/10000).toNumber(),:month=>((key/100)%100).toNumber(),:day=>key%100,:hour=>0,:minute=>0,:second=>0}).value().toLong();
    }
    function commit(){if(!dev){
        data["cachedName"]=speciesName();data["cachedMood"]=mood();data["cachedProgress"]=progress();
        var s=stage();data["cachedSprite"]=s<3?s:3+(family()-1)*3+s-3;
        if(store.changed(data)){store.write("v4",store.copy(data));}
        // Never load the large inventory/history/session document in a 32KB
        // Glance VM. This optional read-only cache does not own pet progress.
        var summary={};var fields=["cachedName","cachedProgress","cachedSprite","poop","energy","fullness","happiness","friendship","lastCare","sleepMode","nextBed","nextWake","scheduleAt","watchBed","watchWake","bedMinute","wakeMinute","sleepUntil"];
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
            data["fullness"]=max(30,number("fullness")-3*((old+h)/6-old/6));
            data["happiness"]=max(40,number("happiness")-2*((old+h)/8-old/8));
            data["energy"]=min(100,number("energy")+5*((old+h)/4-old/4));
            for(var hour=0;hour<h;hour++){
                var at=number("lastCare")+hour*3600+1800;
                if(BeastSleep.sleeping(data,at)){data["energy"]=min(100,number("energy")+8);}
            }
            data["lastCare"]=care>86400?t:number("lastCare")+h*3600;
        }
        if(number("poopDue")>0 && t>=number("poopDue") && number("poop")<2 && t-number("lastPoop")>=14400){
            data["poop"]++;data["cleanliness"]=max(0,number("cleanliness")-15);data["poopDue"]=0l;data["lastPoop"]=t;}
        var prior=number("stageFloor");var s=stage();data["stageFloor"]=max(prior,s);
        if(s>prior && !(dev && number("forcedStage")>=0)){data["evolutionPending"]=1;}
        if(s>=3){family();}if(s==5){var flag=1<<(family()-1);
            if((number("collection")&flag)==0){data["collection"]|=flag;data["charms"]++;}}
    }
    // Watermark + XP + inventory saved in one atomic document, never separately.
    function observe(day,total){
        start();if(dev){return;}BeastActivityRules.observe(data,day,total);
    }
    function syncToday(){syncFromInfo(dev || skipWatch?null:GarminActivity.info());}
    function syncFromInfo(info){
        syncActivity(GarminActivity.steps(info),GarminActivity.minutes(info),GarminActivity.pushes(info));
    }
    function syncActivity(steps,minutes,pushes){
        start();refreshSleepCached();tick();
        if(!dev && !skipWatch){if(steps!=null){observe(today(),steps);}
            activityRewards(today(),steps,minutes,pushes);}
        tick();commit();
    }
    function syncHistory(){
        start();if(!dev && !skipWatch){var h=GarminActivity.history();for(var i=0;i<h.size();i++){
            if(h[i].startOfDay!=null && h[i].steps!=null){observe(dateKey(h[i].startOfDay),h[i].steps);}}}
        refreshSleep();syncToday();
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
    function familyName(){return ["MYSTERY","GROVE","EMBER","TIDE","WISP"][family()];}
    function speciesName(){
        var s=stage();if(s<3){return ["MYSTERY EGG","PIP","NIMBLE"][s];}
        if(number("rare")!=0){return ["LUMENHART","ASHEN PHOENIX","MOONWATER KIRIN","ECLIPSE EIDOLON"][family()-1];}
        return [["MOSSBIT","CINDERCUB","PUDDLEFIN","FLICKLET"],["THORNBUCK","PYROLYNX","CURRENTAIL","NOCTURNE"],
            ["VERDANT ELDER","SOLFLARE","LEVIATHAN","STARWEAVER"]][s-3][family()-1];
    }
    function getTodaySteps(){return GarminActivity.todaySteps();}
    function friendship(){return number("friendship");}function snacks(){return number("snacks");}
    function patsToday(){return number("patDay")==number("day")?number("pats"):0;}
    function careReward(points,personality){
        var credit=min(points,max(0,number("careCap")-number("careToday")));var before=number("careToday")/100;
        data["careGrowth"]+=credit;data["careToday"]+=credit;
        if(credit>0){data["personality"][personality]++;}data["adventure"]+=number("careToday")/100-before;
    }
    function pat(){
        tick();var n=patsToday();if(n>=3){return false;}data["patDay"]=number("day");data["pats"]=n+1;
        data["friendship"]=clamp(friendship()+2);data["happiness"]=clamp(number("happiness")+8);careReward(25,0);commit();return true;
    }
    function feed(){return feedFood(false);}
    function feedFood(meal){
        tick();var key=meal?"meals":"snacks";if(number(key)<1 || number("fullness")>=95){return false;}
        data[key]--;data["fullness"]=clamp(number("fullness")+(meal?30:10));data["happiness"]=clamp(number("happiness")+6);
        data["friendship"]=clamp(friendship()+5);if(number("poopDue")==0){data["poopDue"]=now()+10800;}
        careReward(25,0);commit();return true;
    }
    function clean(){
        tick();if(number("poop")==0){return false;}data["poop"]=0;data["cleanliness"]=100;
        data["happiness"]=clamp(number("happiness")+10);data["friendship"]=clamp(friendship()+3);careReward(30,2);commit();return true;
    }
    function rest(){
        tick();data["sleepUntil"]=now()+3600;if(number("rested")==0){data["energy"]=clamp(number("energy")+20);data["rested"]=1;careReward(25,2);}commit();
    }
    function gameReward(win,kind){
        tick();if(number("games")>=3){return "PRACTICE";}if(number("energy")<10){return "REST FIRST";}
        data["games"]++;data["energy"]-=10;data["happiness"]=clamp(number("happiness")+(win?15:5));
        data["friendship"]=clamp(friendship()+2);careReward(win?75:40,kind==0?1:3);commit();return win?"WELL PLAYED!":"NICE TRY!";
    }
    function beginSession(kind){
        tick();var current=data["sessions"][kind];if(current!=null){return store.copy(current);}
        data["gameSerial"]++;var seed=((realNow()%100000)+number("gameSerial")*719).toNumber();
        var session={"id"=>number("gameSerial"),"kind"=>kind,"round"=>0,"elapsed"=>0,"attempts"=>0,
            "hits"=>0,"score"=>0,"combo"=>0,"best"=>0,"sequence"=>[],"cursor"=>0,"retries"=>0,
            "phase"=>(kind==2?5:1),"route"=>0,"node"=>0,"risk"=>0,"finds"=>0,"seed"=>seed,"travel"=>0,"choice"=>0};
        session["practice"]=kind==2 && number("adventure")<1;
        if(kind==2 && !session["practice"]){data["adventure"]--;}
        data["sessions"][kind]=session;commit();return store.copy(session);
    }
    function saveSession(session){
        var kind=session["kind"];var current=data["sessions"][kind];
        if(current==null || current["id"]!=session["id"] || data["gameClaims"][kind]>=session["id"]){return false;}
        if(!store.same(current,session)){data["sessions"][kind]=store.copy(session);commit();}return true;
    }
    function completeSession(session,win){
        tick();var kind=session["kind"];var current=data["sessions"][kind];
        if(current==null || current["id"]!=session["id"] || data["gameClaims"][kind]>=session["id"]){return "ALREADY SAVED";}
        // Claim + final inventory/reward + removal are one atomic Storage write.
        data["gameClaims"][kind]=session["id"];data["sessions"][kind]=null;
        if(kind==2){
            if(session.hasKey("practice") && session["practice"]){commit();return "SCOUT COMPLETE";}
            // Route choices shape loot pools; an unowned item is favoured without
            // ever requiring activity. Seed is durable: replay/restart cannot reroll.
            var route=session["route"];
            var item=BeastGameRules.treasureItem(session["seed"],session["risk"],session["finds"],route,number("discoveryMask"));
            data["items"][item]++;data["discoveryMask"]=number("discoveryMask")|(1<<item);data["encounters"]++;
            data["personality"][route]++;if(item==0){data["snacks"]=min(12,snacks()+1);}
            data["happiness"]=clamp(number("happiness")+8);data["friendship"]=clamp(friendship()+1);careReward(25,route);
            commit();return "FOUND "+["BERRY","KITE","RIBBON","SHELL","LANTERN","CROWN","CRYSTAL","COMPASS"][item];
        }
        var outcome=gameReward(win,kind);commit();return outcome;
    }
    function explore(choice){
        tick();if(number("adventure")<1){return "EARN ENERGY";}data["adventure"]--;data["encounters"]++;
        var item=(number("encounters")+choice)%8;data["items"][item]++;data["discoveryMask"]=number("discoveryMask")|(1<<item);data["personality"][choice%4]++;
        if(item==0){data["snacks"]=min(12,snacks()+1);}commit();return ["BERRY","KITE","RIBBON","SHELL","LANTERN","CROWN","CRYSTAL","COMPASS"][item];
    }
    function rareEvolve(){
        if(stage()!=5 || friendship()<70 || number("charms")<1 || number("rare")!=0){return false;}
        data["charms"]--;data["rare"]=1;data["rareCollection"]|=1<<(family()-1);commit();return true;
    }
    function useItem(item){
        tick();if(data["items"][item]<1){return false;}
        if(item==0){if(number("fullness")>=95){return false;}data["items"][item]--;data["fullness"]=clamp(number("fullness")+10);if(number("poopDue")==0){data["poopDue"]=now()+10800;}}
        else if(item==1 || item==3 || item==6){data["happiness"]=clamp(number("happiness")+10);careReward(25,item==1?1:3);}
        else{data["equipped"]=number("equipped")==item?-1:item;}
        commit();return true;
    }
    function newEgg(){
        if(stage()!=5){return false;}
        // DEV archives are never persisted, including this explicit operation.
        if(!dev){store.write("v4.archive",store.copy(data));}
        data["petSerial"]++;data["birthEpoch"]=now();data["baseGrowth"]=0l;data["careGrowth"]=0l;data["activityBonus"]=0l;
        data["petXpBaseline"]=xp();data["stageFloor"]=0;data["evolutionPending"]=0;data["family"]=0;data["rare"]=0;
        data["personality"]=[0,0,0,0];data["lastGrowth"]=now();data["growthRemainder"]=0l;commit();return true;
    }
    function mood(){
        return BeastSleep.mood(data,now());
    }
    function enableDev(){
        syncHistory();var b=new TekuTekuBeastState();b.store=store;b.data=store.copy(data);b.dev=true;
        b.testNow=testNow;b.skipWatch=true;b.virtualNow=realNow();b.anchor=realNow();return b;
    }
    function setSpeed(value){virtualNow=now();anchor=realNow();speed=value;}
    function jump(seconds){virtualNow=now()+seconds;anchor=realNow();tick();}
    function devSet(key,value){if(dev){data[key]=value;}}
    function simulateSleep(night){
        if(!dev){return;}data["sleepMode"]=1;
        var minute=BeastSleep.minuteAt(now());data["bedMinute"]=(minute+(night?1439:1))%1440;
        data["wakeMinute"]=(minute+(night?60:1439))%1440;data["sleepUntil"]=0l;
        data["lightsUntil"]=0l;data["nextBed"]=0l;data["nextWake"]=0l;
        if(!night){data["energy"]=80;}
    }
}
