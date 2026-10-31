using Toybox.Graphics;
using Toybox.Timer;
using Toybox.WatchUi;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Application;

class TekuTekuBeastView extends WatchUi.View {
    var beast;var page=0;var refresher=null;var sprite=null;var spriteStage=-1;
    var tick=0;var notice=null;var noticeTicks=0;
    var menu=null;var selection=0;var rows=[];var live=null;var petView=null;
    var animation="idle";var animationTicks=0;
    var frames=null;var spriteFamily=-1;
    var artScale=1.0;var timerPeriod=250;
    // World-space destinations, NOT a multiple of creature size. Only final
    // clipping safety accounts for the sprite's physical extent.
    var roamX=[-0.39,0.38,-0.25,0.28,-0.02,-0.35,0.36,0.05];
    var roamY=[0.56,0.70,0.75,0.58,0.53,0.72,0.66,0.77];var hopHeights=[0,5,9,5];
    var world=null;var scenery=null;var sky=[1,0.5,true];var sceneInk=INK;
    var lastVisual=null;var redrawRequests=0;var displayedSteps=null;
    var lightingStamp=null;
    var updates=null;var updatePrompt=null;var updateVisible=false;
    var nightTint={:tintColor=>0xAAAAAA};
    var roamTicks=0.0;var petX=0.5;var petFoot=0.70;var roamOriginX=0.0;var roamOriginY=0.70;var wasSleeping=false;
    var creatureHeaderBottom=0;var petBounds=[0,0,0,0];var petFrame=0;var darkScene=false;
    var poopRows=[8,28,30,62,127,127];var poopFill=[0,8,12,28,62,0];var poopShine=[0,8,8,0,0,0];
    const BG=0xAAFFAA;const INK=0x005500;const LIGHT=0x55AA55;
    function initialize(){View.initialize();beast=new TekuTekuBeastState();}
    function onShow(){
        updateVisible=true;
        if(refresher!=null){refresher.stop();refresher=null;}
        Application.getApp().activeView=self;if(!beast.dev){beast.data=null;}
        beast.syncHistory();new BeastBattle(beast);loadSprite();ensureWorld();world.beginVisit(beast.today());world.readWatch(beast.realNow(),beast.skipWatch);refresher=new Timer.Timer();timerPeriod=desiredPeriod();refresher.start(method(:refresh),timerPeriod,true);consumeEvolution();
        if(menu!=null && menu.equals("Wild battles")){updateRows();}
        if(Application.getApp().gameView==self){
            if(updates==null){updates=new BeastUpdates(new BeastStore(),BeastBuild.VERSION,BeastBuild.CHANNEL,method(:updateReady));}
            updates.start(updateNow());considerUpdate();
        }
    }
    function onHide(){updateVisible=false;if(refresher!=null){refresher.stop();refresher=null;}if(scenery!=null){scenery.release();}beast.commit();}
    function ensureWorld(){if(world==null || world.dev!=beast.dev){world=new BeastWorld(beast);}if(scenery==null){scenery=new BeastScenery();}}
    function updateNow(){return Toybox.Time.now().value().toLong();}
    function updateEligible(){return updateVisible && Application.getApp().gameView==self && Application.getApp().activeView==self && menu==null && page==0 && notice==null && animationTicks==0;}
    function considerUpdate(){
        if(updates==null || !updates.review || updates.offered || updatePrompt!=null || !updateEligible()){return;}
        var version=updates.offer(updateNow());if(version!=null){updatePrompt=new BeastUpdatePrompt(version);tunePetTimer();}
    }
    function updateReady(){if(updatePrompt==null && updateEligible()){considerUpdate();if(updatePrompt!=null){WatchUi.requestUpdate();}}}
    function dismissUpdate(choice){updates.dismiss(updatePrompt.version,choice,updateNow());updatePrompt=null;tunePetTimer();WatchUi.requestUpdate();}
    function refresh() as Void {
        if(updatePrompt!=null){return;}

        var poopBefore=beast.number("poop");
        var step=timerPeriod/250;tick=(tick+step)%8000;
        var state=visualState();
        if(menu==null && page==0 && beast.number("motion")>0 && beast.stage()>0 && (state.equals("idle") || state.equals("wander") || state.equals("hop") || state.equals("happy"))){
            if(wasSleeping){roamTicks=0.0;roamOriginX=petX-0.5;roamOriginY=petFoot;wasSleeping=false;}
            roamTicks+=step*(beast.number("motion")==1?0.25:1.0)*(beast.number("fullness")<45 || beast.number("happiness")<50 || beast.number("cleanliness")<45?0.5:1.0);
        }
        if(tick%80<step){beast.syncToday();loadSprite();}
        if(beast.dev && tick%4<step){beast.tick();loadSprite();}
        if(beast.number("poop")>poopBefore){animation="hop";animationTicks=8;} // silent reaction
        consumeEvolution();
        if(noticeTicks>0){noticeTicks=beast.max(0,noticeTicks-step);if(noticeTicks==0){notice=null;}}
        if(animationTicks>0){animationTicks=beast.max(0,animationTicks-step);if(animationTicks==0){animation="idle";}}
        // Redraw only changed visible state; no timer survives view hiding.
        if(menu!=null && (menu.equals("Actions") || menu.equals("Lighting")) && (lightingStamp==null || !lightingStamp.equals(lightingKey()))){updateRows();}
        var key=visualKey();
        if(lastVisual==null || !lastVisual.equals(key)){lastVisual=key;redrawRequests++;WatchUi.requestUpdate();}
        tunePetTimer();
    }
    function tunePetTimer(){
        // Navigation must leave the 5s still-screen cadence immediately. Never
        // create/restart a hidden view's timer; lifecycle remains onShow/onHide.
        var wanted=desiredPeriod();if(refresher!=null && wanted!=timerPeriod){timerPeriod=wanted;refresher.stop();refresher.start(method(:refresh),timerPeriod,true);}
    }
    function desiredPeriod(){
        if(updatePrompt!=null){return 5000;}
        if(visualState().equals("tired")){return 5000;}
        if(visualState().equals("grumpy") || visualState().equals("wake")){return beast.number("motion")==0 || menu!=null || page!=0?5000:1000;}
        if(animationTicks>0 || noticeTicks>0){return beast.number("motion")==2 && !visualState().equals("sleep")?250:1000;}
        if(menu!=null || page!=0 || beast.stage()==0 || beast.number("motion")==0 || visualState().equals("sleep")){return 5000;}
        return beast.number("motion")==2 && tick%24<16?250:1000;
    }
    function visualKey(){
        return page+":"+menu+":"+selection+":"+notice+":"+beast.stage()+":"+beast.family()+":"+(beast.progress()*256).toNumber()+":"+beast.xp()+":"+beast.number("fullness")+":"+beast.happiness()+":"+beast.number("energy")+":"+beast.number("cleanliness")+":"+beast.number("poop")+":"+visualState()+":"+beast.isDark()+":"+lightingStamp+":"+(beast.realNow()/60).toNumber()+":"+beast.number("meals")+":"+beast.snacks()+":"+motionKey();
    }
    function lightingKey(){return beast.lightingMode()+":"+beast.isDark()+":"+beast.lightingMinutes()+":"+beast.isSleeping();}
    function lightingLabel(){return ["AUTO","ON","OFF"][beast.lightingMode()];}
    function motionKey(){
        if(menu!=null || page!=0){return 0;}var a=visualState();var m=beast.number("motion");
        if(a.equals("sleep")){return 0;}if(a.equals("evolve")){return 500+tick%4;}
        if(a.equals("grumpy") || a.equals("tired") || a.equals("wake")){return m==0?0:3000+(tick%16<4?1:0);}
        if(m==0){return 0;}if(a.equals("eat")){return 300+(((m==2?tick:(tick/4).toNumber())%4==3)?1:0);}
        if(a.equals("clean")){return 400+tick%3;}if(a.equals("look") || a.equals("blink") || beast.stage()==0){return 0;}
        var s=(roamTicks/(beast.family()==1?2:1)).toNumber();var p=s%48;
        if(p<32 || a.equals("happy") || a.equals("hop")){return 1000+s%384;}
        return 2000+((s/48).toNumber()%8)*100+(p<42?5:(p==45?4:0))*4+(beast.family()==3 && m==2?(s%8<4?2:1):0);
    }
    function consumeEvolution(){
        if(beast.number("evolutionPending")>0){beast.data["evolutionPending"]=0;beast.commit();toast("EVOLVED!","evolve");}
    }
    function toast(text,action){page=0;notice=text;noticeTicks=12;animation=action;animationTicks=12;loadSprite();if(!action.equals("idle")){new FeedbackManager().cue(beast,action);}if(refresher!=null){timerPeriod=desiredPeriod();refresher.stop();refresher.start(method(:refresh),timerPeriod,true);}WatchUi.requestUpdate();}
    function openMenu(name){menu=name;selection=0;updateRows();WatchUi.requestUpdate();}
    function returnToPet(){
        if(petView!=null){petView.menu=null;petView.page=0;petView.selection=0;petView.notice=null;}
        leaveGameMenu();
    }
    function leaveGameMenu(){WatchUi.popView(WatchUi.SLIDE_RIGHT);}
    function updateRows(){
        if(menu.equals("Actions")){rows=beast.number("poop")>0?["Clean","Feed","Play","Pat","Rest","Collection","Settings"]:["Feed","Clean","Play","Pat","Rest","Collection","Settings"];rows.add("Lights: "+lightingLabel());lightingStamp=lightingKey();if(beast.isSleeping()){rows.add("Wake Up");}if(beast.dev){rows.add("Dev Tools");}}
        else if(menu.equals("Lighting")){
            var mode=beast.lightingMode();rows=[(mode==0?"* ":"")+"AUTO",(mode==1?"* ":"")+"ON: 1 hour",(mode==2?"* ":"")+"OFF: 1 hour",
                "Applied: "+(beast.isDark()?"OFF":"ON"),mode==0?(beast.number("autoLights")==1?"Follows bedtime":"Bedtime dim disabled"):"AUTO in "+beast.lightingMinutes()+" min"];
            lightingStamp=lightingKey();
        }
        else if(menu.equals("Feed")){rows=["Meal: "+beast.number("meals"),"Snack: "+beast.snacks()];}
        else if(menu.equals("Care Difficulty")){rows=["Low Maintenance","Normal","High Maintenance"];selection=beast.number("careDifficulty");}
        else if(menu.equals("Settings")){rows=["Developer: "+(beast.dev?"ON":"OFF"),"Sound: "+(beast.number("sound")==0?"OFF":"ON"),"Vibration: "+(beast.number("haptics")==0?"OFF":"ON"),"Motion: "+["OFF","LOW","NORMAL"][beast.number("motion")],"Activity target: "+beast.number("target"),"Bedtime","Feedback test",BeastBuild.LABEL,"Vibe: "+(beast.number("vibeStyle")==0?"GENTLE":"EXPRESSIVE"),"Outdoor world","Care Difficulty"];}
        else if(menu.equals("Bedtime")){rows=["Schedule: "+["WATCH","MANUAL","OFF"][beast.number("sleepMode")],"Bed: "+clockText(beast.number("bedMinute")),"Wake: "+clockText(beast.number("wakeMinute")),"Bedtime dim: "+(beast.number("autoLights")==1?"ON":"OFF"),beast.number("sleepMode")==0?beast.data["sleepSource"]:"LOCAL SCHEDULE"];}
        else if(menu.equals("Feedback test")){rows=["Tone test","Vibration test",FeedbackManager.lastStatus,"Watch Alert Tones","must be ON for sound"];}
        else if(menu.equals("Set time")){rows=[];for(var hour=0;hour<48;hour++){rows.add(clockText(hour*30));}}
        else if(menu.equals("Developer")){rows=["Enable temporary test","Cancel"];}
        else if(menu.equals("Discard DEV?")){rows=["Discard test changes","Keep testing"];}
        else if(menu.equals("Dev Tools")){rows=["Clock speed","Advance time","Force stage","Force family","Adjust needs","Test food / items","Spawn poop","Clean now","Sleep now","Evolve now","Animations","Reset test scenario","Balance settings","Bedtime test","Wake test","Sleepy test","Happy roaming","All needs test"];}
        else if(menu.equals("Reset scenario")){rows=["Copy real beast","Fresh egg","Hungry / messy","Legendary test"];}
        else if(menu.equals("Clock speed")){rows=["1x","5x","20x","100x"];}
        else if(menu.equals("Advance time")){rows=["+1 hour","+1 day","+7 days"];}
        else if(menu.equals("Force stage")){rows=["Egg","Pip","Nimble","Adult","Champion","Legendary","Automatic"];}
        else if(menu.equals("Force family")){rows=["Grove","Ember","Tide","Wisp"];
        }else if(menu.equals("Adjust needs")){rows=["Fullness","Happiness","Energy","Cleanliness","Friendship"];}
        else if(menu.equals("Set value")){rows=["0","25","50","75","100"];}
        else if(menu.equals("Animations")){rows=["idle","wander","hop","blink","look","eat","happy","clean","sleep","evolve","sound test","vibration test"];}
        else if(menu.equals("Balance settings")){rows=["Passive: "+beast.number("passiveRate"),"Care cap: "+beast.number("careCap"),"Hatch hours: "+beast.number("hatchHours"),"Legend days: "+beast.number("legendDays")];}
        else if(menu.equals("Play")){rows=["Beast Bounce","Follow My Lead","Tiny Adventures","Wild battles"];}
        else if(menu.equals("Wild battles")){var fight=new BeastBattle(beast);fight.clearFinishedBattle();var match=fight.battleSession();rows=[fight.hasUnfinishedBattle()?"Resume battle":(match!=null?"View result":"Meet: "+fight.battleQueueCount()+" waiting"),"Practice match","Later","Decline next","Battle XP: "+fight.battleXp(),"Techniques","Wild journal","Walk, care or explore","5 rewarded matches/day","Battle a friend"];}
        else if(menu.equals("Techniques")){var fight=new BeastBattle(beast);rows=[];var moves=BeastBattleMoves.names(BeastBattleMoves.form(beast.stage(),beast.family(),beast.number("rare")));for(var i=0;i<moves.size();i++){rows.add(moves[i]+": "+fight.battleMastery(i));}if(rows.size()==0){rows.add("Hatch before battling");}}
        else if(menu.equals("Wild journal")){var fight=new BeastBattle(beast);rows=[];for(var form=0;form<18;form++){if((fight.data["seen"]&(1<<form))!=0){rows.add(BeastBattleMoves.species(form));}}if(rows.size()==0){rows.add("Meet your first wild beast");}}
        else if(menu.equals("Collection")){rows=["Discoveries","Rare evolution","Archive / new egg","Toys / accessories","Museum"];}
        else if(menu.equals("Toys / accessories")){rows=["Berry","Kite","Ribbon","Shell","Lantern","Crown","Crystal","Compass"];}
        else if(menu.equals("Museum")){rows=[];for(var i=0;i<4;i++){rows.add(["Grove","Ember","Tide","Wisp"][i]+": "+((beast.number("collection")&(1<<i))!=0?"FOUND":"...")+" / "+((beast.number("rareCollection")&(1<<i))!=0?"RARE":"..."));}}
        else if(menu.equals("Archive / new egg")){rows=["Cancel","Archive and start egg"];}
        else{updateWorldRows();}
    }
    function updateWorldRows(){
        ensureWorld();
        if(menu.equals("Outdoor world")){rows=["Environment: "+world.environmentName(),"Sun / location"];if(beast.dev){rows.add("Sky preview");}}
        else if(menu.equals("Environment")){rows=["Family / neutral AUTO","Forest","Meadow","Lakeside","Garden","Autumn Woodland","Countryside","Bamboo Grove","Coastal Beach","Japanese Garden","Winter Woodland","AUTO: change daily"];}
        else if(menu.equals("Sun / location")){world.update(beast.realNow(),!beast.skipWatch);rows=["Location: "+["AUTO","SAVED","MANUAL","FIXED"][world.prefs["locationMode"]],world.source,"Rise "+world.eventText(0)+" Set "+world.eventText(1),"Read watch cache","Approx latitude","Approx longitude","No GPS activation","Moon: decorative arc",world.engine(),world.fixAge(beast.realNow())];}
        else if(menu.equals("Approx latitude") || menu.equals("Approx longitude")){var coord=menu.equals("Approx latitude")?world.draftLat:world.draftLon;rows=[coord.toFloat().format("%.1f")+" degrees","+1 degree","-1 degree","+0.1 degree","-0.1 degree","+10 degrees","-10 degrees","Use this location"];}
        else if(menu.equals("Sky preview")){rows=["Real local sky","Dawn","Day","Dusk","Night"];}
    }
    function clockText(minute){return (minute/60).format("%02d")+":"+(minute%60).format("%02d");}
    var needKey=null;
    function selectAction(){
        if(updatePrompt!=null){dismissUpdate(updatePrompt.choice);return;}
        if(menu==null){openMenu("Actions");return;}
        var name=rows[selection];var n=selection;var context=menu;
        if(beast.isSleeping() && ((context.equals("Actions") && (name.equals("Feed") || name.equals("Pat") || name.equals("Play") || name.equals("Clean") || name.equals("Rest"))) || context.equals("Feed") || context.equals("Play") || context.equals("Toys / accessories"))){
            menu=null;toast("Beast is asleep.","idle");return;
        }
        if(worldAction(context,name,n)){return;}
        if(context.equals("Actions")){
            if(name.equals("Wake Up")){var woke=beast.wakeUp();menu=null;toast(woke?"Waking up.":"Already awake.","wake");return;}
            if(name.find("Lights: ")==0){openMenu("Lighting");return;}
            if(name.equals("Pat")){menu=null;toast(beast.pat()?"HAPPY BEAST!":"PATS: 3/3","happy");}
            else if(name.equals("Clean")){menu=null;var cleaned=beast.clean();toast(beast.number("poop")>0?"POOP LEFT: "+beast.number("poop"):(cleaned?"ALL CLEAN!":"ALL CLEAN"),"clean");}
            else if(name.equals("Rest")){beast.rest();menu=null;toast("RESTING","sleep");}
            else{openMenu(name);}return;
        }
        if(context.equals("Lighting")){
            if(n<3){beast.setLighting(n);menu=null;toast(n==0?"LIGHTS AUTO":(n==1?"ON FOR 1H":"OFF FOR 1H"),"idle");}
            return;
        }
        if(context.equals("Feed")){var fed=beast.feedFood(n==0);menu=null;toast(fed?"YUM!":"FULL / NONE",fed?"eat":"look");return;}
        if(context.equals("Care Difficulty")){beast.setCareDifficulty(n);openMenu("Settings");return;}
        if(context.equals("Settings")){
            if(n==0){openMenu(beast.dev?"Discard DEV?":"Developer");return;}
            if(n==5){openMenu("Bedtime");return;}if(n==6){openMenu("Feedback test");return;}if(n==7){return;}
            if(n==8){beast.data["vibeStyle"]=1-beast.number("vibeStyle");beast.commit();updateRows();WatchUi.requestUpdate();return;}
            if(n==9){openMenu("Outdoor world");return;}if(n==10){openMenu("Care Difficulty");return;}
            var keys=["","sound","haptics","motion","target"];var key=keys[n];
            if(n<3){beast.data[key]=1-beast.number(key);}else if(n==3){beast.data[key]=(beast.number(key)+1)%3;}
            else{beast.data[key]=beast.number(key)==2000?4000:(beast.number(key)==4000?8000:2000);}
            beast.commit();
            if(key.equals("sound") && beast.number("sound")==1){FeedbackManager.lastStatus=new FeedbackManager().soundStatus(beast);openMenu("Feedback test");return;}
            updateRows();WatchUi.requestUpdate();return;
        }
        if(context.equals("Bedtime")){
            if(n==0){beast.data["sleepMode"]=(beast.number("sleepMode")+1)%3;beast.refreshSleep();}
            if(n==1 || n==2){needKey=n==1?"bedMinute":"wakeMinute";selection=0;menu="Set time";rows=[];for(var hour=0;hour<48;hour++){rows.add(clockText(hour*30));}selection=beast.number(needKey)/30;WatchUi.requestUpdate();return;}
            if(n==3){beast.data["autoLights"]=1-beast.number("autoLights");}beast.commit();updateRows();WatchUi.requestUpdate();return;
        }
        if(context.equals("Set time")){beast.data[needKey]=n*30;beast.commit();openMenu("Bedtime");return;}
        if(context.equals("Feedback test")){
            if(n<2){new FeedbackManager().testCue(beast,n==0);updateRows();}WatchUi.requestUpdate();return;
        }
        if(context.equals("Developer")){
            if(n==0){live=beast;beast=beast.enableDev();spriteStage=-1;openMenu("Dev Tools");}else{openMenu("Settings");}return;
        }
        if(context.equals("Discard DEV?")){
            if(n==0){var restored=new TekuTekuBeastState();restored.store=live.store;restored.skipWatch=live.skipWatch;restored.testNow=live.testNow;beast=restored;beast.syncHistory();live=null;spriteStage=-1;menu=null;toast("REAL BEAST","idle");}else{openMenu("Settings");}return;
        }
        if(context.equals("Dev Tools")){
            if(n<5 || n==10 || n==12){openMenu(name);return;}
            if(n==5){beast.devSet("meals",20);beast.devSet("snacks",12);beast.devSet("adventure",20);beast.devSet("charms",4);for(var i=0;i<8;i++){beast.data["items"][i]+=3;}toast("TEST ITEMS","happy");}
            if(n==6){beast.devSet("poop",2);beast.devSet("cleanliness",40);toast("POOP TEST","hop");}
            if(n==7){beast.clean();toast("CLEAN TEST","clean");}
            if(n==8){beast.rest();toast("REST TEST","sleep");}
            if(n==9){beast.devSet("forcedStage",(beast.stage()+1)%6);spriteStage=-1;toast("EVOLVE TEST","evolve");}
            if(n==11){openMenu("Reset scenario");return;}
            if(n==13){beast.simulateSleep(true);toast("BEDTIME TEST","sleep");}
            if(n==14){beast.simulateSleep(false);toast("WAKE TEST","happy");}
            if(n==15){beast.simulateSleep(false);beast.devSet("energy",0);toast("SLEEPY TEST","sleep");}
            if(n==16){beast.simulateSleep(false);beast.devSet("happiness",100);beast.devSet("poop",0);beast.devSet("fullness",80);toast("HAPPY TEST","happy");}
            if(n==17){beast.simulateSleep(false);beast.devSet("happiness",20);beast.devSet("fullness",20);beast.devSet("poop",2);beast.devSet("energy",0);toast("NEEDS TEST","sleep");}
            menu=null;return;
        }
        if(context.equals("Reset scenario")){
            live.data=null;beast=live.enableDev();
            if(n==1){
                beast.devSet("birthEpoch",beast.now());beast.devSet("lastGrowth",beast.now());
                beast.devSet("baseGrowth",0l);beast.devSet("careGrowth",0l);beast.devSet("activityBonus",0l);beast.devSet("growthRemainder",0l);
                beast.devSet("petXpBaseline",beast.xp());beast.devSet("stageFloor",0);beast.devSet("evolutionPending",0);beast.devSet("family",0);
                beast.devSet("forcedStage",-1);beast.devSet("forcedFamily",0);beast.devSet("rare",0);
                beast.devSet("fullness",75);beast.devSet("happiness",65);beast.devSet("energy",80);
                beast.devSet("cleanliness",100);beast.devSet("friendship",0);beast.devSet("poop",0);
                beast.devSet("poopDue",0l);beast.devSet("sleepUntil",0l);beast.devSet("careToday",0);
                beast.devSet("games",0);beast.devSet("pats",0);beast.devSet("meals",2);beast.devSet("snacks",0);
                beast.devSet("personality",[0,0,0,0]);
            }
            if(n==2){beast.devSet("fullness",30);beast.devSet("cleanliness",30);beast.devSet("poop",2);}
            if(n==3){beast.devSet("forcedStage",5);beast.devSet("forcedFamily",1);beast.devSet("friendship",70);beast.devSet("charms",4);}
            spriteStage=-1;menu=null;toast("TEST RESET","idle");return;
        }
        if(context.equals("Clock speed")){beast.setSpeed([1,5,20,100][n]);openMenu("Dev Tools");return;}
        if(context.equals("Advance time")){beast.jump([3600,86400,604800][n]);menu=null;toast("TIME +","evolve");return;}
        if(context.equals("Force stage")){beast.devSet("forcedStage",n==6?-1:n);spriteStage=-1;menu=null;toast("STAGE SET","evolve");return;}
        if(context.equals("Force family")){beast.devSet("forcedFamily",n+1);spriteStage=-1;menu=null;toast("FAMILY TEST","happy");return;}
        if(context.equals("Adjust needs")){needKey=["fullness","happiness","energy","cleanliness","friendship"][n];openMenu("Set value");return;}
        if(context.equals("Set value")){beast.devSet(needKey,n*25);openMenu("Adjust needs");return;}
        if(context.equals("Animations")){
            if(n>=10){new FeedbackManager().testCue(beast,n==10);menu=null;toast(FeedbackManager.lastStatus,"idle");}
            else{menu=null;toast(name.toUpper(),name);}return;}
        if(context.equals("Balance settings")){
            var keys=["passiveRate","careCap","hatchHours","legendDays"];var values=[[6000,12000,18000],[150,300,600],[12,24,36],[14,21,25]];
            var current=beast.number(keys[n]);var index=0;for(var i=0;i<3;i++){if(values[n][i]==current){index=(i+1)%3;}}
            beast.devSet(keys[n],values[n][index]);updateRows();WatchUi.requestUpdate();return;
        }
        if(context.equals("Collection")){
            if(n==0){menu="Discoveries";rows=[];for(var i=0;i<8;i++){rows.add(((beast.number("discoveryMask")&(1<<i))!=0?"* ":"? ")+["Berry","Kite","Ribbon","Shell","Lantern","Crown","Crystal","Compass"][i]+": "+beast.data["items"][i]);}selection=0;}
            if(n==1){var need=beast.stage()<5?"BE A LEGEND":(beast.friendship()<70?"BOND: 70":"NEED CHARM");var evolved=beast.rareEvolve();menu=null;toast(evolved?"RARE FORM!":need,evolved?"evolve":"look");}
            if(n==2){openMenu("Archive / new egg");}if(n==3){openMenu("Toys / accessories");}if(n==4){openMenu("Museum");}WatchUi.requestUpdate();return;
        }
        if(context.equals("Toys / accessories")){menu=null;toast(beast.useItem(n)?name.toUpper():"TRY TRAIL","happy");return;}
        if(context.equals("Archive / new egg")){menu=null;toast(n==1 && beast.newEgg()?"NEW JOURNEY":"BEAST KEPT","evolve");return;}
        if(context.equals("Wild battles")){
            if(n==9){
                if(beast.isSleeping() || beast.stage()==0){menu=null;toast(beast.isSleeping()?"Beast is asleep.":"Hatch before battling","idle");return;}
                frames=null;sprite=null;spriteStage=-1;
                var friend=new BeastFriendView(beast);friend.petView=self;WatchUi.pushView(friend,new BeastBattleInput(friend),WatchUi.SLIDE_LEFT);return;
            }
            var fight=new BeastBattle(beast);
            if(n==0 || n==1){
                if(beast.isSleeping()){menu=null;toast("Beast is asleep.","idle");return;}
                if(beast.stage()==0){menu=null;toast("Hatch before battling","idle");return;}
                var resuming=fight.hasUnfinishedBattle();
                if(n==0){fight.beginBattle();}else{fight.practiceBattle();}
                frames=null;sprite=null;spriteStage=-1; // Do not retain two art sets on small heaps.
                var battle=new BeastBattleView(beast);battle.petView=self;battle.freshBattle=!resuming;WatchUi.pushView(battle,new BeastBattleInput(battle),WatchUi.SLIDE_LEFT);return;
            }
            if(n==2){menu=null;return;}if(n==3){fight.declineEncounter();updateRows();}
            if(n==5){openMenu("Techniques");return;}if(n==6){openMenu("Wild journal");return;}WatchUi.requestUpdate();return;
        }
        if(context.equals("Play")){if(n==3){openMenu("Wild battles");return;}var game=new BeastGameView(beast,n);game.petView=self;WatchUi.pushView(game,new TekuTekuBeastInput(game),WatchUi.SLIDE_LEFT);return;}
        WatchUi.requestUpdate();
    }
    function worldAction(context,name,n){
        if(context.equals("Outdoor world")){openMenu(n==0?"Environment":(n==1?"Sun / location":"Sky preview"));return true;}
        if(context.equals("Environment")){if(n==BeastWorld.THEME_COUNT+1){world.setDailyRotation();}else{world.setTheme(n);}menu=null;toast("WORLD SET","look");return true;}
        if(context.equals("Sky preview")){world.preview=n-1;world.invalidate();menu=null;toast(n==0?"REAL SKY":"SKY PREVIEW","look");return true;}
        if(context.equals("Sun / location")){
            if(n==0){world.prefs["locationMode"]=(world.prefs["locationMode"]+1)%4;world.invalidate();world.save();}
            if(n==3){world.checked=0l;world.readWatch(beast.realNow(),beast.skipWatch);world.invalidate();}
            if(n==4 || n==5){openMenu(name);return true;}updateRows();WatchUi.requestUpdate();return true;
        }
        if(context.equals("Approx latitude") || context.equals("Approx longitude")){
            if(n==7){world.confirmManual();openMenu("Sun / location");return true;}
            if(n>0){var lat=context.equals("Approx latitude");var limit=lat?90:180;
                var value=beast.max(-limit,beast.min(limit,(lat?world.draftLat:world.draftLon)+[0,1,-1,0.1,-0.1,10,-10][n]));
                if(lat){world.draftLat=value;}else{world.draftLon=value;}}
            updateRows();WatchUi.requestUpdate();return true;
        }
        return false;
    }
    function switchPage(delta){
        if(updatePrompt!=null){updatePrompt.move(delta);WatchUi.requestUpdate();return;}
        if(menu!=null){selection=(selection+delta+rows.size())%rows.size();}
        else{page=(page+delta+3)%3;notice=null;}
        tunePetTimer();WatchUi.requestUpdate();
    }
    function touch(point){selectAction();}
    function back(){
        if(updatePrompt!=null){dismissUpdate(0);return true;}
        if(menu!=null){
            if(menu.equals("Lighting")){openMenu("Actions");return true;}
            if(menu.equals("Outdoor world") || menu.equals("Care Difficulty")){openMenu("Settings");return true;}
            if(menu.equals("Environment") || menu.equals("Sun / location") || menu.equals("Sky preview")){openMenu("Outdoor world");return true;}
            if(menu.equals("Approx latitude") || menu.equals("Approx longitude")){openMenu("Sun / location");return true;}
            if(menu.equals("Set time")){openMenu("Bedtime");return true;}
            if(menu.equals("Bedtime") || menu.equals("Feedback test")){openMenu("Settings");return true;}
            if(menu.equals("Wild battles")){openMenu("Play");return true;}
            if(menu.equals("Techniques") || menu.equals("Wild journal")){openMenu("Wild battles");return true;}
            if(menu.equals("Actions")){menu=null;}else if(menu.equals("Settings") || menu.equals("Feed") || menu.equals("Play") || menu.equals("Collection")){openMenu("Actions");}
            else if(menu.equals("Dev Tools")){openMenu("Actions");}else{openMenu(beast.dev?"Dev Tools":"Actions");}
            tunePetTimer();WatchUi.requestUpdate();return true;
        }
        if(page!=0){page=0;tunePetTimer();WatchUi.requestUpdate();return true;}return false;
    }
    function safeTextWidth(dc,y,font){
        var radius=dc.getWidth()/2-8;var c=dc.getHeight()/2;
        var a=y-c;if(a<0){a=-a;}var b=y+dc.getFontHeight(font)-c;if(b<0){b=-b;}var d=a>b?a:b;
        if(d>=radius){return 0;}return (2*Math.sqrt(radius*radius-d*d)).toNumber()-4;
    }
    function label(dc,y,value,font){
        if(dc.getTextWidthInPixels(value,font)>safeTextWidth(dc,y,font)){font=Graphics.FONT_XTINY;}
        var shown=value;while(shown.length()>0 && dc.getTextWidthInPixels(shown,font)>safeTextWidth(dc,y,font)){
            shown=shown.substring(0,shown.length()-1);}
        dc.setColor(menu==null && page==0?sceneInk:INK,Graphics.COLOR_TRANSPARENT);dc.drawText(dc.getWidth()/2,y,font,shown,Graphics.TEXT_JUSTIFY_CENTER);
        var w=dc.getTextWidthInPixels(shown,font);return [dc.getWidth()/2-w/2,y,w,dc.getFontHeight(font),shown];
    }
    function y(dc,fraction){
        // 218px round displays need bottom text slightly higher: font height
        // does not shrink with the screen, so the old chord clipped footers.
        // Keep all existing 240px+ layouts exactly unchanged.
        if(dc.getWidth()<240 && fraction>0.70){fraction=0.70+(fraction-0.70)*0.85;}
        return (dc.getHeight()*fraction).toNumber();
    }
    function loadSprite(){
        var s=beast.stage();var f=beast.family();if(s==spriteStage && f==spriteFamily){return;}spriteStage=s;spriteFamily=f;
        // Release the previous species before allocating its replacement. This
        // avoids a twelve-frame peak on older, non-paged 128KB watches.
        frames=null;sprite=null;
        frames=new BeastArt().petFrames(s,f);sprite=frames[0];artScale=sprite.getWidth()/96.0;
    }
    function creature(dc){
        if(frames==null){return;}
        var active=visualState();var size=sprite.getWidth();var motion=beast.number("motion");
        var centerX=dc.getWidth()*petX;var centerY=dc.getHeight()*petFoot-size/2;
        var frame=0;var stride=roamTicks.toNumber();var moving=false;var left=false;
        var family=beast.family();if(family==1){stride=(stride/2).toNumber();}
        if(active.equals("sleep")){frame=3;centerX=dc.getWidth()*0.30;centerY=dc.getHeight()*0.69-size/2;wasSleeping=true;}
        else if(active.equals("eat")){frame=motion>0 && (motion==2?tick:(tick/4).toNumber())%4==3?0:2;}
        else if(active.equals("look")){frame=5;}
        else if(active.equals("grumpy") || active.equals("tired") || active.equals("wake")){frame=motion>0 && tick%16<4?4:5;}
        else if(active.equals("blink") || active.equals("clean")){frame=4;}
        else if(motion>0 && beast.stage()>0){
            // Travel between 2-D destinations, pause and look; alternating
            // mirrored foot poses and lift avoid a static sliding sprite.
            var part=(stride/48).toNumber()%8;var p=stride%48;var fraction=p<32?p/32.0:1.0;
            var xs=roamX;var ys=roamY;
            var before=(part+7)%8;
            var fromX=stride<48?roamOriginX:xs[before];var fromY=stride<48?roamOriginY:ys[before];
            centerX=dc.getWidth()/2+(fromX+(xs[part]-fromX)*fraction)*dc.getWidth();
            centerY=(fromY+(ys[part]-fromY)*fraction)*dc.getHeight()-size/2;
            moving=p<32;left=xs[part]<fromX;
            frame=moving?BeastArt.walkFrame(beast.stage(),family,stride%2,left):(p<42?5:0);
            if(moving && motion==2){centerY-=stride%2==0?0:3;}
            if(family==3 && motion==2){centerY+=(stride%8<4?2:-2);}
            if(active.equals("happy") || active.equals("hop") || ((beast.number("happiness")>=85 || family==2) && p<8)){
                if(motion==2){centerY-=hopHeights[stride%4];}
                // A moving hop keeps its directional pose; an idle celebration
                // may still blink/turn. Never flip to an unmirrored hop mid-walk.
                if(!moving){frame=stride%2==0?1:4;}
            }
            if(!moving && p==45){frame=4;}
        }
        if(active.equals("evolve")){frame=(tick/2)%2==0?1:4;}
        positionCreature(dc.getWidth(),dc.getHeight(),size,centerX,centerY+size/2);
        var x=petBounds[0];var top=petBounds[1];petFrame=frame;
        petX=(x+size/2)/dc.getWidth().toFloat();petFoot=(top+size)/dc.getHeight().toFloat();
        // Local light follows the beast, not the astronomical sky or sleep state.
        if(scenery!=null){scenery.clearing(dc,x,top,size,sky[0],beast.isDark());}
        // A tiny ground shadow anchors all standing/walking poses.
        dc.setColor(sky[0]==3?0xAAAAAA:0xAAAA55,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(x+size/3,top+size-2,size/3,2);
        // Tint is alpha-mask preserving: sky/transparent padding are untouched.
        // Older renderers retain the native sprite and still get local lighting.
        if(beast.isDark() && (dc has :drawBitmap2)){dc.drawBitmap2(x,top,frames[frame],nightTint);}
        else{dc.drawBitmap(x,top,frames[frame]);}var color=sceneInk;
        if(active.equals("sleep")){pixelIcon(dc,x+size/2-7,top+7,[127,2,4,8,16,32,127],color,2);}
        if(active.equals("grumpy")){pixelIcon(dc,x+size/2-4,top+7,[5,2,5],color,2);}
        if(active.equals("clean")){dc.setColor(0xFFFFFF,Graphics.COLOR_TRANSPARENT);dc.drawCircle(x+size/4,top+size/2,4+tick%3);}
        if(beast.number("rare")==1){pixelIcon(dc,x+size/2-7,top+2,[65,85,127,62],0xFFFF55,2);}
        if(beast.number("equipped")>=0){pixelIcon(dc,x+size/2+12,top+14,[8,28,62,28,8],0xAA55FF,2);}
        if(active.equals("evolve")){dc.setColor(color,Graphics.COLOR_TRANSPARENT);dc.drawCircle(x+size/2,top+size/2,size/2-2-tick%4);}
    }
    function positionCreature(width,height,size,centerX,foot){
        var top=(foot-size).toNumber();
        var upper=(height*0.18).toNumber();var lower=(height*0.745).toNumber()-size;
        if(top<upper){top=upper;}if(top>lower){top=lower;}
        var r=width/2-9;
        var a=top-height/2;if(a<0){a=-a;}var b=top+size-height/2;if(b<0){b=-b;}
        var dy=beast.max(a,b);var half=Math.sqrt(beast.max(0,r*r-dy*dy))-size/2;
        centerX=beast.max(width/2-half,beast.min(width/2+half,centerX));
        var x=(centerX-size/2).toNumber();
        petBounds[0]=x;petBounds[1]=top;petBounds[2]=size;petBounds[3]=size;
    }
    function visualState(){
        // Sleep/tiredness wins over stale celebration or poop reactions.
        if(beast.isSleeping()){return "sleep";}
        if(beast.grump()>0){return "grumpy";}
        if(beast.number("energy")<20){return "tired";}
        if(animationTicks>0 && !animation.equals("idle")){return animation;}
        if(beast.number("fullness")<45){return tick%24<6?"look":"idle";}
        if(beast.number("cleanliness")<45 || beast.number("happiness")<50){return tick%24<8?"look":"idle";}
        return "idle";
    }
    function pixelIcon(dc,x,top,rows,color,scale){
        dc.setColor(color,Graphics.COLOR_TRANSPARENT);for(var r=0;r<rows.size();r++){for(var c=0;c<7;c++){
            if((rows[r]&(1<<(6-c)))!=0){dc.fillRectangle(x+c*scale,top+r*scale,scale,scale);}}}
    }
    function bar(dc,top,value,width){var x=dc.getWidth()/2-width/2;dc.setColor(LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(x,top,width,5);
        dc.setColor(darkScene?BG:INK,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(x,top,(width*value).toNumber(),5);}
    function todayLabel(){
        // One system read per reconciliation, not four reads/second while the
        // pet wanders. This is display-only, never the crediting watermark.
        if(displayedSteps==null || tick%80<timerPeriod/250){displayedSteps=beast.getTodaySteps();}
        var n=displayedSteps;return "STEPS "+(n>=100000?(n/1000).toString()+"K":n.toString());
    }
    function stageLabel(){return ["EGG","HATCHLING","JUVENILE","ADULT","CHAMPION","LEGENDARY"][beast.stage()];}
    function drawPet(dc){
        ensureWorld();sky=world.update(beast.realNow(),!beast.skipWatch);darkScene=sky[0]==3 || beast.isDark();
        scenery.draw(dc,world.choose(beast.family(),beast.today()),sky,beast.isDark());sceneInk=scenery.ink;
        var color=sceneInk;var scale=beast.max(2,(dc.getWidth()/140).toNumber());
        if(beast.number("fullness")<45){pixelIcon(dc,dc.getWidth()/2-10*scale,y(dc,0.12),[8,12,54,127,127,62,28],color,scale);}
        if(beast.happiness()<50){pixelIcon(dc,dc.getWidth()/2-2*scale,y(dc,0.12),[54,127,119,62,28,8],color,scale);}
        if(beast.number("energy")<20 && !visualState().equals("sleep")){pixelIcon(dc,dc.getWidth()/2+6*scale,y(dc,0.12),[14,24,48,48,56,30,15],color,scale);}
        devBadge(dc,color);
        creature(dc);
        drawPoop(dc);
        bar(dc,y(dc,0.80),beast.progress(),dc.getWidth()/2);
        label(dc,y(dc,0.83),notice!=null?notice:todayLabel(),Graphics.FONT_XTINY);
    }
    function poopScale(width){return beast.max(1,(width/140).toNumber());}
    function poopX(width,slot){return (width*(0.26+0.12*slot)-7*poopScale(width)/2.0).toNumber();}
    function poopTop(height){return (height*0.75).toNumber();}
    function drawPoop(dc){
        // Persist slot occupancy, not pixels: positions survive reopening and
        // scale with the display. This grass strip is below every roaming pose
        // and above the growth bar; no collision solver or per-frame arrays.
        var mask=beast.poopMask();if(mask==0){return;}
        var scale=poopScale(dc.getWidth());var top=poopTop(dc.getHeight());
        // Three fixed masks, same 7x6 coverage: dark outline inside the sprite.
        for(var slot=0;slot<5;slot++){
            if((mask&(1<<slot))==0){continue;}var x=poopX(dc.getWidth(),slot);
            pixelIcon(dc,x,top,poopRows,0x000000,scale);
            pixelIcon(dc,x,top,poopFill,0xAA5500,scale);
            pixelIcon(dc,x,top,poopShine,0xFFAA55,scale);
        }
    }

    function devBadge(dc,color){
        if(beast.dev){
            var scale=beast.max(2,(dc.getWidth()/140).toNumber());var x=dc.getWidth()/2-5.5*scale;
            pixelIcon(dc,x,y(dc,0.07),[96,80,80,80,96],color,scale);
            pixelIcon(dc,x+4*scale,y(dc,0.07),[112,64,96,64,112],color,scale);
            pixelIcon(dc,x+8*scale,y(dc,0.07),[80,80,80,80,32],color,scale);
        }
    }
    function drawCare(dc){
        label(dc,y(dc,0.10),beast.dev?"CARE  DEV":"CARE",Graphics.FONT_SMALL);
        var keys=["fullness","happiness","energy","cleanliness"];
        var captions=["FOOD","JOY","ENERGY","CLEAN"];
        for(var i=0;i<4;i++){var top=y(dc,0.25+i*0.13);var value=i==1?beast.happiness():beast.number(keys[i]);label(dc,top,captions[i]+" "+value,Graphics.FONT_XTINY);bar(dc,top+dc.getFontHeight(Graphics.FONT_XTINY)+1,value/100.0,110);}
        label(dc,y(dc,0.81),notice!=null?notice:"M "+beast.number("meals")+" / S "+beast.snacks(),Graphics.FONT_XTINY);
    }
    function drawStats(dc){
        var name=beast.speciesName();var top=y(dc,0.10);var split=name.find(" ");
        if(split!=null && dc.getTextWidthInPixels(name,Graphics.FONT_XTINY)>safeTextWidth(dc,top,Graphics.FONT_XTINY)){
            label(dc,top,name.substring(0,split),Graphics.FONT_XTINY);
            label(dc,top+dc.getFontHeight(Graphics.FONT_XTINY),name.substring(split+1,name.length()),Graphics.FONT_XTINY);
        }else{label(dc,top,name,Graphics.FONT_XTINY);}
        label(dc,y(dc,0.28),stageLabel()+"  DAY "+beast.ageDays(),Graphics.FONT_XTINY);
        label(dc,y(dc,0.38),beast.familyName()+" / "+beast.growth(),Graphics.FONT_XTINY);
        label(dc,y(dc,0.49),"WATCH "+beast.xp(),Graphics.FONT_XTINY);
        label(dc,y(dc,0.60),beast.stage()==0?"HATCH "+beast.hatchDurationHours().toFloat().format("%.0f")+"H":"NEXT "+(beast.nextSteps()/1000)+"K BOND "+beast.friendship(),Graphics.FONT_XTINY);
        label(dc,y(dc,0.71),beast.stage()<3?BeastAffinity.hint(beast.data):(beast.stage()==5?"MASTERY "+beast.mastery():"AGE GATE "+beast.nextAge()+" DAYS"),Graphics.FONT_XTINY);
        label(dc,y(dc,0.82),"ADVENTURE "+beast.number("adventure"),Graphics.FONT_XTINY);
    }
    function drawMenu(dc){
        var heading=menu.equals("Toys / accessories")?"ITEMS":(menu.equals("Archive / new egg")?"NEW EGG":menu);
        label(dc,y(dc,0.12),heading,Graphics.FONT_SMALL);
        if(beast.dev){label(dc,y(dc,0.25),"DEV / TEMPORARY",Graphics.FONT_XTINY);}
        for(var i=-1;i<=1;i++){var index=selection+i;if(index<0 || index>=rows.size()){continue;}
            var top=y(dc,0.52+i*0.15);if(i==0){dc.setColor(LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillRoundedRectangle(dc.getWidth()*0.14,top-2,dc.getWidth()*0.72,dc.getFontHeight(Graphics.FONT_XTINY)+4,4);}
            label(dc,top,rows[index],Graphics.FONT_XTINY);}
        label(dc,y(dc,0.79),(selection+1)+" / "+rows.size(),Graphics.FONT_XTINY);
    }
    function pageDots(dc){for(var i=0;i<3;i++){dc.setColor(i==page?(page==0?sceneInk:INK):LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillCircle(dc.getWidth()/2+(i-1)*14,y(dc,0.92),3);}}
    function onUpdate(dc){considerUpdate();if(updatePrompt!=null){updatePrompt.draw(self,dc);return;}darkScene=menu==null && page==0 && beast.isDark();dc.setColor(darkScene?0x000000:BG,darkScene?0x000000:BG);dc.clear();
        if(menu!=null){drawMenu(dc);}else{if(page==0){drawPet(dc);}else if(page==1){drawCare(dc);}else{drawStats(dc);}pageDots(dc);}}
}
