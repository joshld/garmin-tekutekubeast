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
    var artScale=1.0;
    var creatureHeaderBottom=0;
    const BG=0xAAFFAA;const INK=0x005500;const LIGHT=0x55AA55;
    function initialize(){View.initialize();beast=new TekuTekuBeastState();}
    function onShow(){
        if(refresher!=null){refresher.stop();refresher=null;}
        Application.getApp().activeView=self;if(!beast.dev){beast.data=null;}
        beast.syncHistory();loadSprite();refresher=new Timer.Timer();refresher.start(method(:refresh),250,true);consumeEvolution();
    }
    function onHide(){if(refresher!=null){refresher.stop();refresher=null;}beast.commit();}
    function refresh() as Void {
        var poopBefore=beast.number("poop");
        tick=(tick+1)%8000;
        if(tick%80==0){beast.syncToday();loadSprite();}
        if(beast.dev && tick%4==0){beast.tick();loadSprite();}
        if(beast.number("poop")>poopBefore){animation="hop";animationTicks=8;} // silent reaction
        consumeEvolution();
        if(noticeTicks>0){noticeTicks--;if(noticeTicks==0){notice=null;}}
        if(animationTicks>0){animationTicks--;if(animationTicks==0){animation="idle";}}
        // Sleeping/reduced-motion idle only redraws once a second. No hidden timer.
        if((menu==null && page==0 && beast.number("motion")==2) || tick%4==0 || noticeTicks>0){WatchUi.requestUpdate();}
    }
    function consumeEvolution(){
        if(beast.number("evolutionPending")>0){beast.data["evolutionPending"]=0;beast.commit();toast("EVOLVED!","evolve");}
    }
    function toast(text,action){notice=text;noticeTicks=12;animation=action;animationTicks=12;loadSprite();if(!action.equals("idle")){new FeedbackManager().cue(beast,action);}WatchUi.requestUpdate();}
    function openMenu(name){menu=name;selection=0;updateRows();WatchUi.requestUpdate();}
    function updateRows(){
        if(menu.equals("Actions")){rows=beast.number("poop")>0?["Clean","Feed","Play","Pat","Rest","Collection","Settings"]:["Feed","Clean","Play","Pat","Rest","Collection","Settings"];if(beast.dev){rows.add("Dev Tools");}}
        else if(menu.equals("Feed")){rows=["Meal: "+beast.number("meals"),"Snack: "+beast.snacks()];}
        else if(menu.equals("Settings")){rows=["Developer: "+(beast.dev?"ON":"OFF"),"Sound: "+(beast.number("sound")==0?"OFF":"ON"),"Vibration: "+(beast.number("haptics")==0?"OFF":"ON"),"Motion: "+["OFF","LOW","NORMAL"][beast.number("motion")],"Activity target: "+beast.number("target")];}
        else if(menu.equals("Developer")){rows=["Enable temporary test","Cancel"];}
        else if(menu.equals("Discard DEV?")){rows=["Discard test changes","Keep testing"];}
        else if(menu.equals("Dev Tools")){rows=["Clock speed","Advance time","Force stage","Force family","Adjust needs","Test food / items","Spawn poop","Clean now","Sleep now","Evolve now","Animations","Reset test scenario","Balance settings"];}
        else if(menu.equals("Reset scenario")){rows=["Copy real beast","Fresh egg","Hungry / messy","Legendary test"];}
        else if(menu.equals("Clock speed")){rows=["1x","5x","20x","100x"];}
        else if(menu.equals("Advance time")){rows=["+1 hour","+1 day","+7 days"];}
        else if(menu.equals("Force stage")){rows=["Egg","Pip","Nimble","Adult","Champion","Legendary","Automatic"];}
        else if(menu.equals("Force family")){rows=["Grove","Ember","Tide","Wisp"];
        }else if(menu.equals("Adjust needs")){rows=["Fullness","Happiness","Energy","Cleanliness","Friendship"];}
        else if(menu.equals("Set value")){rows=["0","25","50","75","100"];}
        else if(menu.equals("Animations")){rows=["idle","wander","hop","blink","look","eat","happy","clean","sleep","evolve","sound test","vibration test"];}
        else if(menu.equals("Balance settings")){rows=["Passive: "+beast.number("passiveRate"),"Care cap: "+beast.number("careCap"),"Hatch hours: "+beast.number("hatchHours"),"Legend days: "+beast.number("legendDays")];}
        else if(menu.equals("Play")){rows=["Star Catch","Memory Steps","Trail Treasure"];}
        else if(menu.equals("Collection")){rows=["Discoveries","Rare evolution","Archive / new egg","Toys / accessories","Museum"];}
        else if(menu.equals("Toys / accessories")){rows=["Berry","Kite","Ribbon","Shell","Lantern","Crown","Crystal","Compass"];}
        else if(menu.equals("Museum")){rows=[];for(var i=0;i<4;i++){rows.add(["Grove","Ember","Tide","Wisp"][i]+": "+((beast.number("collection")&(1<<i))!=0?"FOUND":"...")+" / "+((beast.number("rareCollection")&(1<<i))!=0?"RARE":"..."));}}
        else if(menu.equals("Archive / new egg")){rows=["Cancel","Archive and start egg"];}
    }
    var needKey=null;
    function selectAction(){
        if(menu==null){openMenu("Actions");return;}
        var name=rows[selection];var n=selection;var context=menu;
        if(context.equals("Actions")){
            if(name.equals("Pat")){menu=null;toast(beast.pat()?"HAPPY BEAST!":"PATS: 3/3","happy");}
            else if(name.equals("Clean")){menu=null;toast(beast.clean()?"ALL CLEAN!":"ALL CLEAN","clean");}
            else if(name.equals("Rest")){beast.rest();menu=null;toast("RESTING","sleep");}
            else{openMenu(name);}return;
        }
        if(context.equals("Feed")){var fed=beast.feedFood(n==0);menu=null;toast(fed?"YUM!":"FULL / NONE",fed?"eat":"look");return;}
        if(context.equals("Settings")){
            if(n==0){openMenu(beast.dev?"Discard DEV?":"Developer");return;}
            var keys=["","sound","haptics","motion","target"];var key=keys[n];
            if(n<3){beast.data[key]=1-beast.number(key);}else if(n==3){beast.data[key]=(beast.number(key)+1)%3;}
            else{beast.data[key]=beast.number(key)==2000?4000:(beast.number(key)==4000?8000:2000);}
            beast.commit();updateRows();WatchUi.requestUpdate();return;
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
            if(n>=10){var sound=beast.number("sound");var haptics=beast.number("haptics");beast.devSet("sound",n==10?1:0);beast.devSet("haptics",n==11?1:0);new FeedbackManager().cue(beast,"evolve");beast.devSet("sound",sound);beast.devSet("haptics",haptics);menu=null;toast("CUE TEST","idle");}
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
        dc.setColor(INK,Graphics.COLOR_TRANSPARENT);dc.drawText(dc.getWidth()/2,y,font,shown,Graphics.TEXT_JUSTIFY_CENTER);
        var w=dc.getTextWidthInPixels(shown,font);return [dc.getWidth()/2-w/2,y,w,dc.getFontHeight(font),shown];
    }
    function y(dc,fraction){return (dc.getHeight()*fraction).toNumber();}
    function loadSprite(){
        var s=beast.stage();var f=beast.family();if(s==spriteStage && f==spriteFamily){return;}spriteStage=s;spriteFamily=f;
        // Release the previous species before allocating its replacement. This
        // avoids a twelve-frame peak on older, non-paged 128KB watches.
        frames=null;sprite=null;
        frames=new BeastArt().frames(s,f);sprite=frames[0];artScale=sprite.getWidth()/96.0;
    }
    function creature(dc){
        var x=dc.getWidth()/2-48*artScale;var top=y(dc,0.75)-96*artScale;
        var active=animationTicks>0?animation:(beast.mood()=="SLEEPY"?"sleep":"idle");
        if(beast.number("motion")>0){
            if(active.equals("wander") || (active.equals("idle") && tick%80<24)){x+=((tick%24)-12);}
            if(active.equals("hop") || active.equals("happy")){top-=[0,8,16,8][tick%4];}
            if(active.equals("idle") && beast.family()==2 && tick%40<4){top-=[0,8,12,4][tick%4];}
            if(active.equals("idle") && beast.family()==3){top-=[0,2,4,2][(tick/2)%4];}
            if(active.equals("idle") && beast.family()==4){x+=[0,4,8,4][(tick/3)%4];}
        }
        var minimumTop=creatureHeaderBottom+2-8*artScale;if(top<minimumTop){top=minimumTop;}
        var frame=0;
        if(active.equals("sleep")){frame=3;}
        else if(active.equals("eat")){frame=tick%2==0?2:0;}
        else if(active.equals("happy")){frame=tick%2==0?4:0;}
        else if(active.equals("wander") || active.equals("look") || (active.equals("idle") && tick%80<24)){frame=tick%2;}
        if(active.equals("blink") || (active.equals("idle") && tick%40==30)){frame=4;}
        if(active.equals("look") || (active.equals("idle") && tick%80>=40 && tick%80<45)){frame=5;}
        if(active.equals("clean")){frame=4;}
        if(frames!=null){dc.drawBitmap(x,top,frames[frame]);}
        if(active.equals("sleep")){dc.setColor(INK,Graphics.COLOR_TRANSPARENT);dc.drawText(dc.getWidth()/2+50,top+8*artScale,Graphics.FONT_XTINY,"z",Graphics.TEXT_JUSTIFY_CENTER);}
        if(active.equals("clean")){dc.setColor(0xFFFFFF,Graphics.COLOR_TRANSPARENT);dc.fillCircle(x+15,top+75,5+tick%4);}
        if(active.equals("eat")){pixelIcon(dc,x+78,top+70,[8,28,62,127,65,127],INK,2);}
        if(beast.number("rare")==1){pixelIcon(dc,dc.getWidth()/2-7,top+4,[65,85,127,62],0xFFFF55,2);}
        var accessory=beast.number("equipped");
        if(accessory>=0){pixelIcon(dc,x+75,top+12,accessory==5?[65,85,127,62]:[8,28,62,28,8],accessory==5?0xFFFF55:0xAA55FF,2);}
        if(active.equals("evolve")){dc.setColor(0xFFFFFF,Graphics.COLOR_TRANSPARENT);dc.drawCircle(dc.getWidth()/2,top+48*artScale,44*artScale+tick%4);}
        if(beast.number("poop")>0){pixelIcon(dc,dc.getWidth()/2+48*artScale+4,y(dc,0.63),[8,28,30,62,127,127],INK,2);}
    }
    function pixelIcon(dc,x,top,rows,color,scale){
        dc.setColor(color,Graphics.COLOR_TRANSPARENT);for(var r=0;r<rows.size();r++){for(var c=0;c<7;c++){
            if((rows[r]&(1<<(6-c)))!=0){dc.fillRectangle(x+c*scale,top+r*scale,scale,scale);}}}
    }
    function bar(dc,top,value,width){var x=dc.getWidth()/2-width/2;dc.setColor(LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(x,top,width,5);
        dc.setColor(INK,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(x,top,(width*value).toNumber(),5);}
    function todayLabel(){var n=beast.getTodaySteps();return "STEPS "+(n>=100000?(n/1000).toString()+"K":n.toString());}
    function stageLabel(){return ["EGG","HATCHLING","JUVENILE","ADULT","CHAMPION","LEGENDARY"][beast.stage()];}
    function drawPet(dc){
        var name=beast.speciesName();var nameY=y(dc,0.11);var split=-1;
        if(dc.getTextWidthInPixels(name,Graphics.FONT_XTINY)>safeTextWidth(dc,nameY,Graphics.FONT_XTINY)){
            for(var i=1;i<name.length();i++){if(name.substring(i,i+1).equals(" ")){split=i;break;}}
        }
        var nameBottom=0;
        if(split>0){label(dc,nameY,name.substring(0,split),Graphics.FONT_XTINY);label(dc,nameY+dc.getFontHeight(Graphics.FONT_XTINY),name.substring(split+1,name.length()),Graphics.FONT_XTINY);nameBottom=nameY+2*dc.getFontHeight(Graphics.FONT_XTINY);}
        else{var box=label(dc,nameY,name,Graphics.FONT_SMALL);nameBottom=nameY+box[3];}
        var cx=dc.getWidth()/2;var top=y(dc,0.28);if(top<nameBottom+3){top=nameBottom+3;}
        creatureHeaderBottom=top+14;
        pixelIcon(dc,cx-54,top,[54,127,127,62,28,8],beast.number("happiness")>=50?INK:LIGHT,2);
        pixelIcon(dc,cx-20,top,[8,28,62,127,65,127],beast.number("fullness")>=45?INK:LIGHT,2);
        pixelIcon(dc,cx+14,top,[12,24,56,127,14,28,24],beast.number("energy")>=20?INK:LIGHT,2);
        if(beast.dev){dc.setColor(INK,Graphics.COLOR_TRANSPARENT);dc.drawText(cx+49,top-4,Graphics.FONT_XTINY,"DEV",Graphics.TEXT_JUSTIFY_LEFT);}
        creature(dc);bar(dc,y(dc,0.78),beast.progress(),dc.getWidth()/2);
        label(dc,y(dc,0.83),notice!=null?notice:todayLabel(),Graphics.FONT_XTINY);
    }
    function drawCare(dc){
        label(dc,y(dc,0.10),beast.dev?"CARE  DEV":"CARE",Graphics.FONT_SMALL);
        var keys=["fullness","happiness","energy","cleanliness"];
        var captions=["FOOD","JOY","ENERGY","CLEAN"];
        for(var i=0;i<4;i++){var top=y(dc,0.25+i*0.13);label(dc,top,captions[i]+" "+beast.number(keys[i]),Graphics.FONT_XTINY);bar(dc,top+dc.getFontHeight(Graphics.FONT_XTINY)+1,beast.number(keys[i])/100.0,110);}
        label(dc,y(dc,0.81),notice!=null?notice:"M "+beast.number("meals")+" / S "+beast.snacks(),Graphics.FONT_XTINY);
    }
    function drawStats(dc){
        label(dc,y(dc,0.10),beast.familyName()+(beast.dev?" DEV":""),Graphics.FONT_SMALL);
        label(dc,y(dc,0.26),stageLabel()+"  DAY "+beast.ageDays(),Graphics.FONT_XTINY);
        label(dc,y(dc,0.38),"GROWTH "+beast.growth(),Graphics.FONT_XTINY);
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
    function onUpdate(dc){dc.setColor(BG,BG);dc.clear();
        if(menu!=null){drawMenu(dc);}else{if(page==0){drawPet(dc);}else if(page==1){drawCare(dc);}else{drawStats(dc);}pageDots(dc);}}
}
