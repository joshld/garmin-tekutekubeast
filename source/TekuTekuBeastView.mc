using Toybox.Graphics;
using Toybox.Timer;
using Toybox.WatchUi;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Application;

class TekuTekuBeastView extends WatchUi.View {
    var beast;var page=0;var refresher=null;var sprite=null;var spriteStage=-1;
    var tick=0;var notice=null;var noticeTicks=0;
    var menu=null;var selection=0;var rows=[];var live=null;
    var animation="idle";var animationTicks=0;
    var frames=null;var spriteFamily=-1;
    var artScale=1.0;var timerPeriod=250;
    var roamX=[-0.09,0.09,0.04,-0.09];var roamY=[0.02,-0.06,0.05,0.02];var hopHeights=[0,9,17,9];
    var creatureHeaderBottom=0;var petBounds=[0,0,0,0];var petFrame=0;var darkScene=false;
    const BG=0xAAFFAA;const INK=0x005500;const LIGHT=0x55AA55;
    function initialize(){View.initialize();beast=new TekuTekuBeastState();}
    function onShow(){
        if(refresher!=null){refresher.stop();refresher=null;}
        Application.getApp().activeView=self;if(!beast.dev){beast.data=null;}
        beast.syncHistory();loadSprite();refresher=new Timer.Timer();timerPeriod=desiredPeriod();refresher.start(method(:refresh),timerPeriod,true);consumeEvolution();
    }
    function onHide(){if(refresher!=null){refresher.stop();refresher=null;}beast.commit();}
    function refresh() as Void {
        var poopBefore=beast.number("poop");
        var step=timerPeriod/250;tick=(tick+step)%8000;
        if(tick%80<step){beast.syncToday();loadSprite();}
        if(beast.dev && tick%4<step){beast.tick();loadSprite();}
        if(beast.number("poop")>poopBefore){animation="hop";animationTicks=8;} // silent reaction
        consumeEvolution();
        if(noticeTicks>0){noticeTicks=beast.max(0,noticeTicks-step);if(noticeTicks==0){notice=null;}}
        if(animationTicks>0){animationTicks=beast.max(0,animationTicks-step);if(animationTicks==0){animation="idle";}}
        // Sleeping/reduced-motion idle only redraws once a second. No hidden timer.
        if((menu==null && page==0 && beast.number("motion")==2) || tick%4<step || noticeTicks>0){WatchUi.requestUpdate();}
        var wanted=desiredPeriod();if(refresher!=null && wanted!=timerPeriod){timerPeriod=wanted;refresher.stop();refresher.start(method(:refresh),timerPeriod,true);}
    }
    function desiredPeriod(){return menu==null && page==0 && beast.number("motion")==2 && !beast.isSleeping() && beast.number("energy")>=20 && (animationTicks>0 || tick%24<16)?250:1000;}
    function consumeEvolution(){
        if(beast.number("evolutionPending")>0){beast.data["evolutionPending"]=0;beast.commit();toast("EVOLVED!","evolve");}
    }
    function toast(text,action){page=0;notice=text;noticeTicks=12;animation=action;animationTicks=12;loadSprite();if(!action.equals("idle")){new FeedbackManager().cue(beast,action);}WatchUi.requestUpdate();}
    function openMenu(name){menu=name;selection=0;updateRows();WatchUi.requestUpdate();}
    function updateRows(){
        if(menu.equals("Actions")){rows=beast.number("poop")>0?["Clean","Feed","Play","Pat","Rest","Collection","Settings"]:["Feed","Clean","Play","Pat","Rest","Collection","Settings"];rows.add(beast.isDark()?"Lights On":"Lights Off");if(beast.dev){rows.add("Dev Tools");}}
        else if(menu.equals("Feed")){rows=["Meal: "+beast.number("meals"),"Snack: "+beast.snacks()];}
        else if(menu.equals("Settings")){rows=["Developer: "+(beast.dev?"ON":"OFF"),"Sound: "+(beast.number("sound")==0?"OFF":"ON"),"Vibration: "+(beast.number("haptics")==0?"OFF":"ON"),"Motion: "+["OFF","LOW","NORMAL"][beast.number("motion")],"Activity target: "+beast.number("target"),"Bedtime","Feedback test","Version 0.5.0 beta","Vibe: "+(beast.number("vibeStyle")==0?"GENTLE":"EXPRESSIVE")];}
        else if(menu.equals("Bedtime")){rows=["Schedule: "+["WATCH","MANUAL","OFF"][beast.number("sleepMode")],"Bed: "+clockText(beast.number("bedMinute")),"Wake: "+clockText(beast.number("wakeMinute")),"Auto lights: "+(beast.number("autoLights")==1?"ON":"OFF"),beast.number("sleepMode")==0?beast.data["sleepSource"]:"LOCAL SCHEDULE"];}
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
        else if(menu.equals("Play")){rows=["Beast Bounce","Follow My Lead","Tiny Adventures"];}
        else if(menu.equals("Collection")){rows=["Discoveries","Rare evolution","Archive / new egg","Toys / accessories","Museum"];}
        else if(menu.equals("Toys / accessories")){rows=["Berry","Kite","Ribbon","Shell","Lantern","Crown","Crystal","Compass"];}
        else if(menu.equals("Museum")){rows=[];for(var i=0;i<4;i++){rows.add(["Grove","Ember","Tide","Wisp"][i]+": "+((beast.number("collection")&(1<<i))!=0?"FOUND":"...")+" / "+((beast.number("rareCollection")&(1<<i))!=0?"RARE":"..."));}}
        else if(menu.equals("Archive / new egg")){rows=["Cancel","Archive and start egg"];}
    }
    function clockText(minute){return (minute/60).format("%02d")+":"+(minute%60).format("%02d");}
    var needKey=null;
    function selectAction(){
        if(menu==null){openMenu("Actions");return;}
        var name=rows[selection];var n=selection;var context=menu;
        if(context.equals("Actions")){
            if(name.equals("Lights Off") || name.equals("Lights On")){beast.toggleLights();menu=null;toast("LIGHTS: 1 HOUR","idle");return;}
            if(name.equals("Pat")){menu=null;toast(beast.pat()?"HAPPY BEAST!":"PATS: 3/3","happy");}
            else if(name.equals("Clean")){menu=null;toast(beast.clean()?"ALL CLEAN!":"ALL CLEAN","clean");}
            else if(name.equals("Rest")){beast.rest();menu=null;toast("RESTING","sleep");}
            else{openMenu(name);}return;
        }
        if(context.equals("Feed")){var fed=beast.feedFood(n==0);menu=null;toast(fed?"YUM!":"FULL / NONE",fed?"eat":"look");return;}
        if(context.equals("Settings")){
            if(n==0){openMenu(beast.dev?"Discard DEV?":"Developer");return;}
            if(n==5){openMenu("Bedtime");return;}if(n==6){openMenu("Feedback test");return;}if(n==7){return;}
            if(n==8){beast.data["vibeStyle"]=1-beast.number("vibeStyle");beast.commit();updateRows();WatchUi.requestUpdate();return;}
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
        if(context.equals("Play")){var game=new BeastGameView(beast,n);WatchUi.pushView(game,new TekuTekuBeastInput(game),WatchUi.SLIDE_LEFT);return;}
        WatchUi.requestUpdate();
    }
    function switchPage(delta){
        if(menu!=null){selection=(selection+delta+rows.size())%rows.size();}
        else{page=(page+delta+3)%3;notice=null;}
        WatchUi.requestUpdate();
    }
    function touch(point){selectAction();}
    function back(){
        if(menu!=null){
            if(menu.equals("Set time")){openMenu("Bedtime");return true;}
            if(menu.equals("Bedtime") || menu.equals("Feedback test")){openMenu("Settings");return true;}
            if(menu.equals("Actions")){menu=null;}else if(menu.equals("Settings") || menu.equals("Feed") || menu.equals("Play") || menu.equals("Collection")){openMenu("Actions");}
            else if(menu.equals("Dev Tools")){openMenu("Actions");}else{openMenu(beast.dev?"Dev Tools":"Actions");}
            WatchUi.requestUpdate();return true;
        }
        if(page!=0){page=0;WatchUi.requestUpdate();return true;}return false;
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
        dc.setColor(darkScene?BG:INK,Graphics.COLOR_TRANSPARENT);dc.drawText(dc.getWidth()/2,y,font,shown,Graphics.TEXT_JUSTIFY_CENTER);
        var w=dc.getTextWidthInPixels(shown,font);return [dc.getWidth()/2-w/2,y,w,dc.getFontHeight(font),shown];
    }
    function y(dc,fraction){return (dc.getHeight()*fraction).toNumber();}
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
        var centerX=dc.getWidth()/2;var centerY=dc.getHeight()*0.49;
        var frame=0;var stride=motion==2?tick:(tick/4).toNumber();var moving=false;var left=false;
        var family=beast.family();if(family==1){stride=(stride/2).toNumber();}if(family==4){stride+=32;}
        if(active.equals("sleep")){frame=3;}
        else if(active.equals("eat")){frame=2;}
        else if(active.equals("look")){frame=5;}
        else if(active.equals("blink") || active.equals("clean")){frame=4;}
        else if(motion>0 && beast.stage()>0){
            // Travel between 2-D destinations, pause and look; alternating
            // mirrored foot poses and lift avoid a static sliding sprite.
            var part=(stride/24).toNumber()%4;var p=stride%24;var fraction=p<16?p/16.0:1.0;
            var xs=roamX;var ys=roamY;
            var before=(part+3)%4;var amplitude=motion==1?0.45:1.0;
            if(beast.number("fullness")<45){amplitude*=0.55;}
            centerX+=(xs[before]+(xs[part]-xs[before])*fraction)*dc.getWidth()*amplitude;
            centerY+=(ys[before]+(ys[part]-ys[before])*fraction)*dc.getHeight()*amplitude;
            moving=p<16;left=xs[part]<xs[before];
            frame=moving?(left?6:0)+stride%2:(p<20?5:0);
            if(moving && motion==2){centerY-=stride%2==0?0:3;}
            if(family==3 && motion==2){centerY+=(stride%8<4?2:-2);}
            if(active.equals("happy") || active.equals("hop") || ((beast.number("happiness")>=85 || family==2) && p<8)){
                if(motion==2){centerY-=hopHeights[stride%4];}frame=stride%2==0?1:4;
            }
            if(!moving && p==22){frame=4;}
        }
        if(active.equals("evolve")){frame=(tick/2)%2==0?1:4;}
        var top=(centerY-size/2).toNumber();
        var upper=y(dc,0.18);var lower=y(dc,0.745)-size;
        if(top<upper){top=upper;}if(top>lower){top=lower;}
        var r=dc.getWidth()/2-9;
        var a=top-dc.getHeight()/2;if(a<0){a=-a;}var b=top+size-dc.getHeight()/2;if(b<0){b=-b;}
        var dy=beast.max(a,b);var half=Math.sqrt(beast.max(0,r*r-dy*dy))-size/2;
        if(beast.number("poop")>0){centerX=beast.min(centerX,dc.getWidth()*0.66-size/2);}
        centerX=beast.max(dc.getWidth()/2-half,beast.min(dc.getWidth()/2+half,centerX));
        var x=(centerX-size/2).toNumber();petFrame=frame;
        petBounds[0]=x;petBounds[1]=top;petBounds[2]=size;petBounds[3]=size;
        dc.drawBitmap(x,top,frames[frame]);var color=darkScene?BG:INK;
        if(active.equals("sleep")){pixelIcon(dc,x+size/2-7,top+7,[127,2,4,8,16,32,127],color,2);}
        if(active.equals("clean")){dc.setColor(0xFFFFFF,Graphics.COLOR_TRANSPARENT);dc.drawCircle(x+size/4,top+size/2,4+tick%3);}
        if(beast.number("rare")==1){pixelIcon(dc,x+size/2-7,top+2,[65,85,127,62],0xFFFF55,2);}
        if(beast.number("equipped")>=0){pixelIcon(dc,x+size/2+12,top+14,[8,28,62,28,8],0xAA55FF,2);}
        if(active.equals("evolve")){dc.setColor(color,Graphics.COLOR_TRANSPARENT);dc.drawCircle(x+size/2,top+size/2,size/2-2-tick%4);}
    }
    function visualState(){
        // Sleep/tiredness wins over stale celebration or poop reactions.
        if(beast.isSleeping() || beast.number("energy")<20){return "sleep";}
        if(animationTicks>0 && !animation.equals("idle")){return animation;}
        if(beast.number("fullness")<45){return tick%24<6?"look":"idle";}
        return "idle";
    }
    function pixelIcon(dc,x,top,rows,color,scale){
        dc.setColor(color,Graphics.COLOR_TRANSPARENT);for(var r=0;r<rows.size();r++){for(var c=0;c<7;c++){
            if((rows[r]&(1<<(6-c)))!=0){dc.fillRectangle(x+c*scale,top+r*scale,scale,scale);}}}
    }
    function bar(dc,top,value,width){var x=dc.getWidth()/2-width/2;dc.setColor(LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(x,top,width,5);
        dc.setColor(darkScene?BG:INK,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(x,top,(width*value).toNumber(),5);}
    function todayLabel(){var n=beast.getTodaySteps();return "STEPS "+(n>=100000?(n/1000).toString()+"K":n.toString());}
    function stageLabel(){return ["EGG","HATCHLING","JUVENILE","ADULT","CHAMPION","LEGENDARY"][beast.stage()];}
    function drawPet(dc){
        var color=darkScene?BG:INK;var count=0;
        if(beast.number("fullness")<45){pixelIcon(dc,dc.getWidth()/2-28,y(dc,0.12),[8,12,54,127,127,62,28],color,2);count++;}
        if(beast.number("happiness")<50){pixelIcon(dc,dc.getWidth()/2-7,y(dc,0.12),[54,127,119,62,28,8],color,2);count++;}
        if(beast.number("energy")<20 && !visualState().equals("sleep")){pixelIcon(dc,dc.getWidth()/2+14,y(dc,0.12),[14,24,48,48,56,30,15],color,2);count++;}
        devBadge(dc,color);
        creature(dc);
        // Poop is a fixed floor object, not attached to the moving creature.
        if(beast.number("poop")>0){var scale=beast.max(2,(dc.getWidth()/140).toNumber());pixelIcon(dc,dc.getWidth()*0.73,y(dc,0.73),[8,28,30,62,127,127],0xAA5500,scale);}
        bar(dc,y(dc,0.80),beast.progress(),dc.getWidth()/2);
        label(dc,y(dc,0.83),notice!=null?notice:todayLabel(),Graphics.FONT_XTINY);
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
        for(var i=0;i<4;i++){var top=y(dc,0.25+i*0.13);label(dc,top,captions[i]+" "+beast.number(keys[i]),Graphics.FONT_XTINY);bar(dc,top+dc.getFontHeight(Graphics.FONT_XTINY)+1,beast.number(keys[i])/100.0,110);}
        label(dc,y(dc,0.81),notice!=null?notice:"M "+beast.number("meals")+" / S "+beast.snacks(),Graphics.FONT_XTINY);
    }
    function drawStats(dc){
        var name=beast.speciesName();var top=y(dc,0.10);var split=name.find(" ");
        if(split!=null && dc.getTextWidthInPixels(name,Graphics.FONT_XTINY)>safeTextWidth(dc,top,Graphics.FONT_XTINY)){
            label(dc,top,name.substring(0,split),Graphics.FONT_XTINY);
            label(dc,top+dc.getFontHeight(Graphics.FONT_XTINY),name.substring(split+1,name.length()),Graphics.FONT_XTINY);
        }else{label(dc,top,name,Graphics.FONT_XTINY);}
        label(dc,y(dc,0.26),stageLabel()+"  DAY "+beast.ageDays(),Graphics.FONT_XTINY);
        label(dc,y(dc,0.38),beast.familyName()+" / "+beast.growth(),Graphics.FONT_XTINY);
        label(dc,y(dc,0.49),"WATCH "+beast.xp(),Graphics.FONT_XTINY);
        label(dc,y(dc,0.60),beast.stage()==0?"HATCH "+beast.hatchDurationHours().toFloat().format("%.0f")+"H":"NEXT "+(beast.nextSteps()/1000)+"K BOND "+beast.friendship(),Graphics.FONT_XTINY);
        label(dc,y(dc,0.71),beast.stage()==5?"MASTERY "+beast.mastery():"AGE GATE "+beast.nextAge()+" DAYS",Graphics.FONT_XTINY);
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
    function pageDots(dc){for(var i=0;i<3;i++){dc.setColor(i==page?INK:LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillCircle(dc.getWidth()/2+(i-1)*14,y(dc,0.92),3);}}
    function onUpdate(dc){darkScene=menu==null && page==0 && beast.isDark();dc.setColor(darkScene?0x000000:BG,darkScene?0x000000:BG);dc.clear();
        if(menu!=null){drawMenu(dc);}else{if(page==0){drawPet(dc);}else if(page==1){drawCare(dc);}else{drawStats(dc);}pageDots(dc);}}
}
