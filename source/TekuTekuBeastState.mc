// Foreground care, games and owner tools. Canonical data/API remain inherited.
class TekuTekuBeastState extends BeastStateCore {
    var battleData=null;
    var virtualNow=0l; var anchor=0l; var speed=1;
    function initialize(){BeastStateCore.initialize();}
    function now(){return dev?virtualNow+max(0l,realNow()-anchor)*speed:realNow();}
    function scheduleFoodPoop(meal){BeastCareRules.feed(data,now(),meal);}
    function setCareDifficulty(mode){
        start();if(mode<0 || mode>2){return;}tick();BeastCareRules.advance(data,now(),true);data["careDifficulty"]=mode;commit();
    }
    function wakeUp(){
        start();if(!isSleeping()){return false;}tick();var t=now();
        var until=number("sleepUntil");if(isNight()){until=max(until,BeastSleep.scheduleEnd(data,t));}
        var level=BeastSleep.wakeAnnoyance(data,t);
        // Retain nap history for lazy energy accounting. This bounded interval
        // suppresses only the current sleep; Rest explicitly starts a new one.
        data["awakeAt"]=t;data["awakeUntil"]=min(until,t+86400);data["awakeZone"]=BeastSleep.zoneAt(t);
        data["grumpAt"]=t;data["grumpLevel"]=level;commit();return true;
    }
    function isDark(){return BeastSleep.dark(data,now());}
    function lightingMode(){return BeastSleep.lightingMode(data,now());}
    function lightingMinutes(){return BeastSleep.lightingMinutes(data,now());}
    function setLighting(mode){
        if(mode<0 || mode>2){return;}
        data["lights"]=mode==2?1:0;data["lightsUntil"]=mode==0?0l:now()+3600;commit();
    }
    function toggleLights(){setLighting(isDark()?1:2);}
    function syncToday(){syncFromInfo(dev || skipWatch?null:GarminActivity.info());}
    function syncFromInfo(info){
        syncActivity(GarminActivity.steps(info),GarminActivity.minutes(info),GarminActivity.pushes(info));
    }
    function syncHistory(){
        start();if(!dev && !skipWatch){var h=GarminActivity.history();for(var i=0;i<h.size();i++){
            if(h[i].startOfDay!=null && h[i].steps!=null){observe(dateKey(h[i].startOfDay),h[i].steps);}}}
        refreshSleep();syncToday();
    }
    function familyName(){return ["MYSTERY","GROVE","EMBER","TIDE","WISP"][family()];}
    function patsToday(){return number("patDay")==number("day")?number("pats"):0;}
    function careReward(points,personality){
        var credit=min(points,max(0,number("careCap")-number("careToday")));var before=number("careToday")/100;
        data["careGrowth"]+=credit;data["careToday"]+=credit;
        if(credit>0){data["personality"][personality]++;}data["adventure"]+=number("careToday")/100-before;
    }
    function pat(){
        start();if(isSleeping()){return false;}tick();var n=patsToday();if(n>=3){return false;}data["patDay"]=number("day");data["pats"]=n+1;
        data["friendship"]=clamp(friendship()+2);data["happiness"]=clamp(number("happiness")+5);careReward(25,0);commit();return true;
    }
    function feed(){return feedFood(false);}
    function feedFood(meal){
        start();if(isSleeping()){return false;}tick();var key=meal?"meals":"snacks";if(number(key)<1 || number("fullness")>=95){return false;}
        data[key]--;data["fullness"]=clamp(number("fullness")+(meal?20:6));data["happiness"]=clamp(number("happiness")+3);
        data["friendship"]=clamp(friendship()+5);scheduleFoodPoop(meal);
        careReward(25,0);commit();return true;
    }
    function clean(){
        start();if(isSleeping()){return false;}tick();if(number("poop")==0){return false;}
        var mask=number("poopSlots");for(var i=0;i<5;i++){if((mask&(1<<i))!=0){mask&=~(1<<i);break;}}
        data["poop"]--;data["poopSlots"]=mask;
        data["cleanliness"]=number("poop")==0?100:min(100-15*number("poop"),number("cleanliness")+15);
        // A backlog takes several actions, not several happiness/bond rewards.
        if(now()-number("lastCleanReward")>=14400){
            data["lastCleanReward"]=now();data["happiness"]=clamp(number("happiness")+3);
            data["friendship"]=clamp(friendship()+3);careReward(30,2);
        }
        commit();return true;
    }
    function rest(){
        start();if(isSleeping()){return;}tick();data["awakeAt"]=0l;data["awakeUntil"]=0l;
        data["grumpAt"]=0l;data["grumpLevel"]=0;
        data["sleepUntil"]=now()+3600;if(number("rested")==0){data["energy"]=clamp(number("energy")+20);data["rested"]=1;careReward(25,2);}commit();
    }
    function gameReward(win,kind){
        start();if(isSleeping()){return "Beast is asleep.";}tick();if(number("games")>=3){return "PRACTICE";}if(number("energy")<10){return "REST FIRST";}
        data["games"]++;data["energy"]-=10;data["happiness"]=clamp(number("happiness")+(win?8:3));
        data["friendship"]=clamp(friendship()+2);careReward(win?75:40,kind==0?1:3);commit();return win?"WELL PLAYED!":"NICE TRY!";
    }
    function beginSession(kind){
        start();if(isSleeping()){return null;}tick();var current=data["sessions"][kind];if(current!=null){return store.copy(current);}
        data["gameSerial"]++;var seed=((realNow()%100000)+number("gameSerial")*719).toNumber();
        var session={"id"=>number("gameSerial"),"kind"=>kind,"round"=>0,"elapsed"=>0,"attempts"=>0,
            "hits"=>0,"score"=>0,"combo"=>0,"best"=>0,"sequence"=>[],"cursor"=>0,"retries"=>0,
            "phase"=>(kind==2?5:1),"route"=>0,"node"=>0,"risk"=>0,"finds"=>0,"seed"=>seed,"travel"=>0,"choice"=>0};
        session["practice"]=kind==2 && number("adventure")<1;
        if(kind==2 && !session["practice"]){data["adventure"]--;}
        data["sessions"][kind]=session;commit();return store.copy(session);
    }
    function abandonSession(session){
        if(session==null){return false;}
        var kind=session["kind"];var current=data["sessions"][kind];
        if(current==null || current["id"]!=session["id"]){return false;}
        // Retire without completing: no result, reward, refund or daily claim.
        data["sessions"][kind]=null;commit();return true;
    }
    function saveSession(session){
        var kind=session["kind"];var current=data["sessions"][kind];
        if(current==null || current["id"]!=session["id"] || data["gameClaims"][kind]>=session["id"]){return false;}
        if(!store.same(current,session)){data["sessions"][kind]=store.copy(session);commit();}return true;
    }
    function completeSession(session,win){
        start();if(isSleeping()){return "Beast is asleep.";}tick();var kind=session["kind"];var current=data["sessions"][kind];
        if(current==null || current["id"]!=session["id"] || data["gameClaims"][kind]>=session["id"]){return "ALREADY SAVED";}
        // Claim + final inventory/reward + removal are one atomic Storage write.
        data["gameClaims"][kind]=session["id"];data["sessions"][kind]=null;
        BeastAffinity.credit(data,kind==2?session["route"]+1:(kind==0?2:4),win?2:1,number("day"));
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
        start();if(isSleeping()){return "Beast is asleep.";}tick();if(number("adventure")<1){return "EARN ENERGY";}data["adventure"]--;data["encounters"]++;
        var item=(number("encounters")+choice)%8;data["items"][item]++;data["discoveryMask"]=number("discoveryMask")|(1<<item);data["personality"][choice%4]++;BeastAffinity.credit(data,choice%4+1,2,number("day"));
        if(item==0){data["snacks"]=min(12,snacks()+1);}commit();return ["BERRY","KITE","RIBBON","SHELL","LANTERN","CROWN","CRYSTAL","COMPASS"][item];
    }
    function rareEvolve(){
        if(stage()!=5 || friendship()<70 || number("charms")<1 || number("rare")!=0){return false;}
        data["charms"]--;data["rare"]=1;data["rareCollection"]|=1<<(family()-1);commit();return true;
    }
    function useItem(item){
        start();if(isSleeping()){return false;}tick();if(data["items"][item]<1){return false;}
        if(item==0){if(number("fullness")>=95){return false;}data["items"][item]--;data["fullness"]=clamp(number("fullness")+6);scheduleFoodPoop(false);}
        else if(item==1 || item==3 || item==6){BeastAffinity.credit(data,item==1?2:(item==3?3:4),1,number("day"));var room=max(0,number("careCap")-number("careToday"));if(room>0){data["happiness"]=clamp(number("happiness")+3);}careReward(25,item==1?1:3);}
        else{data["equipped"]=number("equipped")==item?-1:item;}
        commit();return true;
    }
    function newEgg(){
        if(stage()!=5){return false;}
        // DEV archives are never persisted, including this explicit operation.
        if(!dev){store.write("v4.archive",store.copy(data));}
        data["petSerial"]++;data["birthEpoch"]=now();data["baseGrowth"]=0l;data["careGrowth"]=0l;data["activityBonus"]=0l;
        data["petXpBaseline"]=xp();data["stageFloor"]=0;data["evolutionPending"]=0;data["family"]=0;data["rare"]=0;
        data["personality"]=[0,0,0,0];data["affinity"]=[0,0,0,0];data["affinityToday"]=[0,0,0,0];data["affinityDay"]=number("day");
        data["temperament"]=BeastAffinity.temperament(number("birthEpoch"),number("petSerial"));data["lastGrowth"]=now();data["growthRemainder"]=0l;
        data["awakeAt"]=0l;data["awakeUntil"]=0l;data["grumpAt"]=0l;data["grumpLevel"]=0;commit();return true;
    }
    function enableDev(){
        syncHistory();var b=new TekuTekuBeastState();b.store=store;b.data=store.copy(data);b.dev=true;
        b.testNow=testNow;b.skipWatch=true;b.virtualNow=realNow();b.anchor=realNow();return b;
    }
    function setSpeed(value){virtualNow=now();anchor=realNow();speed=value;}
    function jump(seconds){virtualNow=now()+seconds;anchor=realNow();tick();}
    function devSet(key,value){if(dev){data[key]=value;if(key.equals("poop")){repairPoop();}}}
    function simulateSleep(night){
        if(!dev){return;}data["sleepMode"]=1;
        data["awakeAt"]=0l;data["awakeUntil"]=0l;data["grumpAt"]=0l;data["grumpLevel"]=0;
        var minute=BeastSleep.minuteAt(now());data["bedMinute"]=(minute+(night?1439:1))%1440;
        data["wakeMinute"]=(minute+(night?60:1439))%1440;data["sleepUntil"]=0l;
        data["lightsUntil"]=0l;data["nextBed"]=0l;data["nextWake"]=0l;
        if(!night){data["energy"]=80;}
    }
}
