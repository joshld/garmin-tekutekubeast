using Toybox.Graphics;
using Toybox.Timer;
using Toybox.WatchUi;
using Toybox.Lang;
using Toybox.Math;

class TekuTekuBeastView extends WatchUi.View {
    var beast;var page=0;var refresher=null;var sprite=null;var spriteStage=-1;
    var tick=0;var notice=null;var noticeTicks=0;
    var menu=null;var selection=0;var rows=[];var live=null;
    var animation="idle";var animationTicks=0;
    const BG=0xAAFFAA;const INK=0x005500;const LIGHT=0x55AA55;
    function initialize(){View.initialize();beast=new TekuTekuBeastState();}
    function onShow(){beast.syncHistory();loadSprite();refresher=new Timer.Timer();refresher.start(method(:refresh),250,true);}
    function onHide(){if(refresher!=null){refresher.stop();refresher=null;}beast.commit();}
    function refresh() as Void {
        tick=(tick+1)%8000;
        if(tick%80==0){beast.syncToday();loadSprite();}
        if(beast.dev && tick%4==0){beast.tick();loadSprite();}
        if(noticeTicks>0){noticeTicks--;if(noticeTicks==0){notice=null;}}
        if(animationTicks>0){animationTicks--;if(animationTicks==0){animation="idle";}}
        // Sleeping/reduced-motion idle only redraws once a second. No hidden timer.
        if(beast.number("motion")==2 || tick%4==0 || noticeTicks>0){WatchUi.requestUpdate();}
    }
    function toast(text,action){notice=text;noticeTicks=12;animation=action;animationTicks=12;loadSprite();WatchUi.requestUpdate();}
    function openMenu(name){menu=name;selection=0;updateRows();WatchUi.requestUpdate();}
    function updateRows(){
        if(menu.equals("Actions")){rows=beast.number("poop")>0?["Clean","Feed","Play","Pat","Rest","Collection","Settings"]:["Feed","Clean","Play","Pat","Rest","Collection","Settings"];if(beast.dev){rows.add("Dev Tools");}}
        else if(menu.equals("Feed")){rows=["Meal: "+beast.number("meals"),"Snack: "+beast.snacks()];}
        else if(menu.equals("Settings")){rows=["Developer: "+(beast.dev?"ON":"OFF"),"Sound: "+(beast.number("sound")==0?"OFF":"ON"),"Vibration: "+(beast.number("haptics")==0?"OFF":"ON"),"Motion: "+["OFF","LOW","NORMAL"][beast.number("motion")],"Activity target: "+beast.number("target")];}
        else if(menu.equals("Developer")){rows=["Enable temporary test","Cancel"];}
        else if(menu.equals("Discard DEV?")){rows=["Discard test changes","Keep testing"];}
        else if(menu.equals("Dev Tools")){rows=["Clock speed","Advance time","Force stage","Force family","Adjust needs","Test food / items","Spawn poop","Clean now","Sleep now","Evolve now","Animations","Reset test scenario","Balance settings"];}
        else if(menu.equals("Clock speed")){rows=["1x","5x","20x","100x"];}
        else if(menu.equals("Advance time")){rows=["+1 hour","+1 day","+7 days"];}
        else if(menu.equals("Force stage")){rows=["Egg","Pip","Nimble","Adult","Champion","Legendary","Automatic"];}
        else if(menu.equals("Force family")){rows=["Grove","Ember","Tide","Wisp"];
        }else if(menu.equals("Adjust needs")){rows=["Fullness","Happiness","Energy","Cleanliness","Friendship"];}
        else if(menu.equals("Set value")){rows=["0","25","50","75","100"];}
        else if(menu.equals("Animations")){rows=["idle","wander","hop","blink","look","eat","happy","clean","sleep","evolve"];}
        else if(menu.equals("Balance settings")){rows=["Passive: "+beast.number("passiveRate"),"Care cap: "+beast.number("careCap"),"Hatch hours: "+beast.number("hatchHours"),"Legend days: "+beast.number("legendDays")];}
        else if(menu.equals("Play")){rows=["Star Catch","Memory Steps","Trail Treasure"];}
        else if(menu.equals("Collection")){rows=["Discoveries","Rare evolution","Archive / new egg"];}
        else if(menu.equals("Archive / new egg")){rows=["Cancel","Archive and start egg"];}
    }
    var needKey=null;
    function selectAction(){
        if(menu==null){openMenu("Actions");return;}
        var name=rows[selection];var n=selection;var context=menu;
        if(context.equals("Actions")){
            if(name.equals("Pat")){menu=null;toast(beast.pat()?"HAPPY BEAST!":"PATS: 3/3","happy");}
            else if(name.equals("Clean")){menu=null;toast(beast.clean()?"ALL CLEAN!":"ALREADY CLEAN","clean");}
            else if(name.equals("Rest")){beast.rest();menu=null;toast("SWEET DREAMS","sleep");}
            else{openMenu(name);}return;
        }
        if(context.equals("Feed")){menu=null;toast(beast.feedFood(n==0)?"YUM!":"FULL / NO FOOD","eat");return;}
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
            if(n==0){var restored=new TekuTekuBeastState();restored.store=live.store;restored.skipWatch=live.skipWatch;restored.testNow=live.testNow;beast=restored;beast.syncHistory();live=null;spriteStage=-1;menu=null;toast("REAL BEAST RESTORED","idle");}else{openMenu("Settings");}return;
        }
        if(context.equals("Dev Tools")){
            if(n<5 || n==10 || n==12){openMenu(name);return;}
            if(n==5){beast.devSet("meals",20);beast.devSet("snacks",12);beast.devSet("adventure",20);beast.devSet("charms",4);toast("TEST INVENTORY","happy");}
            if(n==6){beast.devSet("poop",2);beast.devSet("cleanliness",40);toast("POOP TEST","hop");}
            if(n==7){beast.clean();toast("CLEAN TEST","clean");}
            if(n==8){beast.rest();toast("REST TEST","sleep");}
            if(n==9){beast.devSet("forcedStage",(beast.stage()+1)%6);spriteStage=-1;toast("EVOLUTION TEST","evolve");}
            if(n==11){live.data=null;beast=live.enableDev();spriteStage=-1;toast("TEST RESET","idle");}
            menu=null;return;
        }
        if(context.equals("Clock speed")){beast.setSpeed([1,5,20,100][n]);openMenu("Dev Tools");return;}
        if(context.equals("Advance time")){beast.jump([3600,86400,604800][n]);menu=null;toast("TIME ADVANCED","evolve");return;}
        if(context.equals("Force stage")){beast.devSet("forcedStage",n==6?-1:n);spriteStage=-1;menu=null;toast("STAGE PREVIEW","evolve");return;}
        if(context.equals("Force family")){beast.devSet("forcedFamily",n+1);spriteStage=-1;menu=null;toast("FAMILY PREVIEW","happy");return;}
        if(context.equals("Adjust needs")){needKey=["fullness","happiness","energy","cleanliness","friendship"][n];openMenu("Set value");return;}
        if(context.equals("Set value")){beast.devSet(needKey,n*25);openMenu("Adjust needs");return;}
        if(context.equals("Animations")){menu=null;toast(name.toUpper(),name);return;}
        if(context.equals("Balance settings")){
            var keys=["passiveRate","careCap","hatchHours","legendDays"];var values=[[6000,12000,18000],[150,300,600],[12,24,36],[14,21,25]];
            var current=beast.number(keys[n]);var index=0;for(var i=0;i<3;i++){if(values[n][i]==current){index=(i+1)%3;}}
            beast.devSet(keys[n],values[n][index]);updateRows();WatchUi.requestUpdate();return;
        }
        if(context.equals("Collection")){
            if(n==0){menu="Discoveries";rows=[];for(var i=0;i<8;i++){rows.add(["Berry","Kite","Ribbon","Shell","Lantern","Crown","Crystal","Compass"][i]+": "+beast.data["items"][i]);}selection=0;}
            if(n==1){menu=null;toast(beast.rareEvolve()?"RARE EVOLUTION!":"NEED LEGEND / BOND 70","evolve");}
            if(n==2){openMenu("Archive / new egg");}WatchUi.requestUpdate();return;
        }
        if(context.equals("Archive / new egg")){menu=null;toast(n==1 && beast.newEgg()?"NEW JOURNEY":"BEAST KEPT","evolve");return;}
        if(context.equals("Play")){menu=null;toast("GAME IN DEVELOPMENT","happy");return;}
        WatchUi.requestUpdate();
    }
    function switchPage(delta){
        if(menu!=null){selection=(selection+delta+rows.size())%rows.size();}
        else{page=(page+delta+3)%3;notice=null;}
        WatchUi.requestUpdate();
    }
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
        var s=beast.stage();if(s==spriteStage){return;}spriteStage=s;
        sprite=WatchUi.loadResource(s==0?Rez.Drawables.Egg:(s==1?Rez.Drawables.Pip:Rez.Drawables.Nimble));
    }
    function creature(dc){
        var x=dc.getWidth()/2-56;var top=y(dc,0.34);
        var active=animationTicks>0?animation:(beast.mood()=="SLEEPY"?"sleep":"idle");
        if(beast.number("motion")>0){
            if(active.equals("wander") || (active.equals("idle") && tick%80<24)){x+=((tick%24)-12);}
            if(active.equals("hop") || active.equals("happy") || active.equals("evolve")){top-=[0,8,16,8][tick%4];}
        }
        if(sprite!=null){dc.drawBitmap(x,top,sprite);}
        if(active.equals("sleep")){label(dc,y(dc,0.29),"z z Z",Graphics.FONT_XTINY);}
        if(active.equals("clean")){dc.setColor(0xFFFFFF,Graphics.COLOR_TRANSPARENT);dc.fillCircle(x+15,top+75,5+tick%4);}
        if(active.equals("eat")){pixelIcon(dc,x+78,top+70,[8,28,62,127,65,127],INK,2);}
        if(beast.number("poop")>0){pixelIcon(dc,dc.getWidth()/2+56,y(dc,0.63),[8,28,30,62,127,127],INK,2);}
    }
    function pixelIcon(dc,x,top,rows,color,scale){
        dc.setColor(color,Graphics.COLOR_TRANSPARENT);for(var r=0;r<rows.size();r++){for(var c=0;c<7;c++){
            if((rows[r]&(1<<(6-c)))!=0){dc.fillRectangle(x+c*scale,top+r*scale,scale,scale);}}}
    }
    function bar(dc,top,value,width){var x=dc.getWidth()/2-width/2;dc.setColor(LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(x,top,width,7);
        dc.setColor(INK,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(x,top,(width*value).toNumber(),7);}
    function todayLabel(){var n=beast.getTodaySteps();return "STEPS "+(n>=100000?(n/1000).toString()+"K":n.toString());}
    function stageLabel(){return ["EGG","HATCHLING","JUVENILE","ADULT","CHAMPION","LEGENDARY"][beast.stage()];}
    function drawPet(dc){
        label(dc,y(dc,0.12),beast.speciesName(),Graphics.FONT_SMALL);
        label(dc,y(dc,0.26),beast.dev?"DEV  "+beast.speed+"x":beast.mood(),Graphics.FONT_XTINY);
        creature(dc);bar(dc,y(dc,0.78),beast.progress(),dc.getWidth()/2);
        label(dc,y(dc,0.83),notice!=null?notice:todayLabel(),Graphics.FONT_XTINY);
    }
    function drawCare(dc){
        label(dc,y(dc,0.10),beast.dev?"CARE  DEV":"CARE",Graphics.FONT_SMALL);
        var keys=["fullness","happiness","energy","cleanliness"];
        var captions=["FOOD","JOY","ENERGY","CLEAN"];
        for(var i=0;i<4;i++){var top=y(dc,0.27+i*0.12);label(dc,top,captions[i]+" "+beast.number(keys[i]),Graphics.FONT_XTINY);bar(dc,top+23,beast.number(keys[i])/100.0,110);}
        label(dc,y(dc,0.79),notice!=null?notice:"MEALS "+beast.number("meals")+"  SNACKS "+beast.snacks(),Graphics.FONT_XTINY);
    }
    function drawStats(dc){
        label(dc,y(dc,0.10),beast.familyName()+(beast.dev?" DEV":""),Graphics.FONT_SMALL);
        label(dc,y(dc,0.26),stageLabel()+"  DAY "+beast.ageDays(),Graphics.FONT_XTINY);
        label(dc,y(dc,0.38),"GROWTH "+beast.growth(),Graphics.FONT_XTINY);
        label(dc,y(dc,0.49),"WATCH "+beast.xp(),Graphics.FONT_XTINY);
        label(dc,y(dc,0.60),"BOND "+beast.friendship()+"  XP NEXT "+beast.nextSteps(),Graphics.FONT_XTINY);
        label(dc,y(dc,0.71),beast.stage()==5?"MASTERY "+beast.mastery():"AGE GATE "+beast.nextAge()+" DAYS",Graphics.FONT_XTINY);
        label(dc,y(dc,0.82),"ADVENTURE "+beast.number("adventure"),Graphics.FONT_XTINY);
    }
    function drawMenu(dc){
        label(dc,y(dc,0.12),menu,Graphics.FONT_SMALL);
        if(beast.dev){label(dc,y(dc,0.25),"DEV / TEMPORARY",Graphics.FONT_XTINY);}
        for(var i=-1;i<=1;i++){var index=selection+i;if(index<0 || index>=rows.size()){continue;}
            var top=y(dc,0.48+i*0.15);if(i==0){dc.setColor(LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillRoundedRectangle(dc.getWidth()*0.14,top-2,dc.getWidth()*0.72,29,4);}
            label(dc,top,rows[index],Graphics.FONT_XTINY);}
        label(dc,y(dc,0.79),(selection+1)+" / "+rows.size(),Graphics.FONT_XTINY);
    }
    function pageDots(dc){for(var i=0;i<3;i++){dc.setColor(i==page?INK:LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillCircle(dc.getWidth()/2+(i-1)*14,y(dc,0.92),3);}}
    function onUpdate(dc){dc.setColor(BG,BG);dc.clear();
        if(menu!=null){drawMenu(dc);}else{if(page==0){drawPet(dc);}else if(page==1){drawCare(dc);}else{drawStats(dc);}pageDots(dc);}}
}
