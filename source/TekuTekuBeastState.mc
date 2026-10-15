using Toybox.ActivityMonitor;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Lang;

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
        store.write("v4.migration",store.copy(data));commit();
    }
    function calendarMoment(key){
        return Gregorian.moment({:year=>(key/10000).toNumber(),:month=>((key/100)%100).toNumber(),:day=>key%100,:hour=>0,:minute=>0,:second=>0}).value().toLong();
    }
    function commit(){if(!dev){
        data["cachedName"]=speciesName();data["cachedMood"]=mood();data["cachedProgress"]=progress();
        var s=stage();data["cachedSprite"]=s<3?s:3+(family()-1)*3+s-3;
        store.write("v4",store.copy(data));}}
    function xp(){return number("xp");} // genuine lifetime watch steps ONLY
    function growth(){return number("baseGrowth")+number("careGrowth")+number("activityBonus")+max(0l,xp()-number("petXpBaseline"));}
    function ageDays(){return (max(0l,now()-number("birthEpoch"))/86400).toNumber();}
    function oldStage(x,a){
        if(x>=300000 && a>=21){return 5;}if(x>=150000 && a>=14){return 4;}
        if(x>=70000 && a>=7){return 3;}if(x>=20000 && a>=2){return 2;}return x>=2000?1:0;
    }
    function stage(){
        if(dev && number("forcedStage")>=0){return number("forcedStage");}
        var s=oldStage(growth(),ageDays());
        if(s==1 && number("stageFloor")==0){
            var h=max(0l,now()-number("birthEpoch"))/3600.0;
            s=h>=hatchDurationHours()?1:0;
        }
        if(s==0 && now()-number("birthEpoch")>=number("hatchHours")*3600){s=1;}
        if(growth()>=300000 && ageDays()>=number("legendDays")){s=5;}
        if(s==5 && ageDays()<number("legendDays")){s=4;}
        return max(number("stageFloor"),s);
    }
    function hatchDurationHours(){
        // Full optional care can accelerate incubation equally to activity.
        var bonus=min(16,max(number("activityBonus"),max(0l,xp()-number("petXpBaseline")))/1000.0+number("careGrowth")/(max(1,number("careCap"))/16.0));
        return max(number("hatchMinimum"),number("hatchHours")-bonus);
    }
    function mastery(){return stage()<5?0:1+max(0l,(growth()-300000)/25000);}
    function masteryProgress(){return max(0l,growth()-300000)%25000;}
    function nextSteps(){return [12000,20000,70000,150000,300000,325000][stage()];}
    function nextAge(){return [1,2,7,14,number("legendDays"),0][stage()];}
    function progress(){
        if(stage()==5){return masteryProgress()/25000.0;}
        if(stage()==0){return min(1.0,max(0l,now()-number("birthEpoch"))/(hatchDurationHours()*3600.0));}
        var previous=[0,2000,20000,70000,150000][stage()];
        return min(1.0,max(0l,growth()-previous)/(nextSteps()-previous).toFloat());
    }
    function tick(){
        start();var t=now();var elapsed=max(0l,t-number("lastGrowth"));
        if(elapsed>0){var units=elapsed*number("passiveRate")+number("growthRemainder");
            data["baseGrowth"]+=units/86400;data["growthRemainder"]=units%86400;data["lastGrowth"]=t;}
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
        start();if(dev || day<number("birth") || total<0){return;}
        var eligible=max(0,total-(day==number("birth")?number("birthBaseline"):0));var slot=day%32;
        var previous=data["days"][slot]==day?data["counts"][slot]:0;
        if(eligible<=previous){return;}
        data["days"][slot]=day;data["counts"][slot]=eligible;var delta=eligible-previous;data["xp"]+=delta;
        var food=number("snackRemainder")+delta;data["snacks"]=min(12,number("snacks")+food/2500);data["snackRemainder"]=food%2500;
    }
    function syncToday(){
        start();tick();
        if(!dev && !skipWatch){var info=ActivityMonitor.getInfo();if(info.steps!=null){observe(today(),info.steps);}
            var minutes=null;var pushes=null;
            if(info has :activeMinutesDay){var a=info.activeMinutesDay;if(a!=null){minutes=a.moderate+a.vigorous;}}
            if(info has :pushes){pushes=info.pushes;}
            activityRewards(today(),info.steps,minutes,pushes);}
        tick();commit();
    }
    function syncHistory(){
        start();if(!dev && !skipWatch){var h=ActivityMonitor.getHistory();for(var i=0;i<h.size();i++){
            if(h[i].startOfDay!=null && h[i].steps!=null){observe(dateKey(h[i].startOfDay),h[i].steps);}}}
        syncToday();
    }
    function activityRewards(day,steps,minutes,pushes){
        if(dev || day!=number("day")){return;}var n=0;
        if(steps!=null){var slot=day%32;n=(data["days"][slot]==day?data["counts"][slot]:0)/number("target");}
        if(minutes!=null){if(number("minutesBase")<0){data["minutesBase"]=minutes;}n=max(n,max(0,minutes-number("minutesBase"))/10);}
        if(pushes!=null){if(number("pushBase")<0){data["pushBase"]=pushes;}n=max(n,max(0,pushes-number("pushBase"))/500);}
        // Same physical effort measured by several APIs only earns once.
        n=min(5,n);if(n>number("activityMilestone")){var delta=n-number("activityMilestone");data["adventure"]+=delta;data["activityBonus"]=number("activityBonus")+delta*number("activityUnitGrowth");data["activityMilestone"]=n;}
    }
    function family(){
        if(dev && number("forcedFamily")>0){return number("forcedFamily");}if(stage()<3){return 0;}
        if(number("family")!=0){return number("family");}
        var scores=store.copy(data["personality"]);var big=0;var steady=0;var moderate=0;var easy=0;
        for(var i=0;i<32;i++){if(data["days"][i]==0){continue;}var n=data["counts"][i];
            if(n>=18000){big++;}if(n>=6000){steady++;}if(n>=3000){moderate++;}else{easy++;}}
        if(big>=2){scores[1]+=8;}if(steady>=5){scores[0]+=8;}if(moderate>=3 && easy>=1){scores[2]+=8;}
        var winner=((number("birthEpoch")%4+number("petSerial"))%4).toNumber();
        for(var i=0;i<4;i++){if(scores[i]>scores[winner]){winner=i;}}
        data["family"]=winner+1;return winner+1;
    }
    function familyName(){return ["MYSTERY","GROVE","EMBER","TIDE","WISP"][family()];}
    function speciesName(){
        var s=stage();if(s<3){return ["MYSTERY EGG","PIP","NIMBLE"][s];}
        if(number("rare")!=0){return ["LUMENHART","ASHEN PHOENIX","MOONWATER KIRIN","ECLIPSE EIDOLON"][family()-1];}
        return [["MOSSBIT","CINDERCUB","PUDDLEFIN","FLICKLET"],["THORNBUCK","PYROLYNX","CURRENTAIL","NOCTURNE"],
            ["VERDANT ELDER","SOLFLARE","LEVIATHAN","STARWEAVER"]][s-3][family()-1];
    }
    function getTodaySteps(){var i=ActivityMonitor.getInfo();return i.steps==null?0:i.steps;}
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
        if(number("poop")>0){return "MESSY";}if(number("sleepUntil")>now() || number("energy")<20){return "SLEEPY";}
        if(number("fullness")<45){return "HUNGRY";}if(number("happiness")>=85){return "EXCITED";}
        if(number("happiness")>=70){return "PLAYFUL";}return friendship()>=25?"CONTENT":"COZY";
    }
    function enableDev(){
        syncHistory();var b=new TekuTekuBeastState();b.store=store;b.data=store.copy(data);b.dev=true;
        b.testNow=testNow;b.skipWatch=true;b.virtualNow=realNow();b.anchor=realNow();return b;
    }
    function setSpeed(value){virtualNow=now();anchor=realNow();speed=value;}
    function jump(seconds){virtualNow=now()+seconds;anchor=realNow();tick();}
    function devSet(key,value){if(dev){data[key]=value;}}
}
