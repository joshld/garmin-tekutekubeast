using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;

// This is an internal QA harness, NOT the on-watch Developer Mode application.
class ArtPreviewState extends TekuTekuBeastState {
    var previewStage=0;var previewFamily=0;var stress=0;
    function initialize(){
        TekuTekuBeastState.initialize();store.memory={};skipWatch=true;start();
        dev=true;virtualNow=realNow();anchor=realNow();
    }
    function syncToday(){}function syncHistory(){}
    function stage(){return previewStage;}
    function family(){return previewStage<3?0:previewFamily;}
    function getTodaySteps(){return stress==0?12345:1000000;}
}
class AuditGame extends BeastGameView {
    var owner;
    function initialize(b,k,a){BeastGameView.initialize(b,k);owner=a;}
    function label(dc,top,value,font){var box=BeastGameView.label(dc,top,value,font);owner.capture(box,value);return box;}
}
class ArtLayoutAuditView extends TekuTekuBeastView {
    var boxes=[];var failures=[];var scenes=[];var cursor=0;var audited=false;var showSummary=true;
    var exitWhenDone=false;var exitScheduled=false;
    var peakMemory=0;var totalMemory=0;

    // Generate one scene per callback: bounded RAM and no constructor watchdog.
    var menuNames=["Actions","Feed","Settings","Developer","Discard DEV?","Dev Tools","Clock speed","Advance time","Force stage","Force family","Adjust needs","Set value","Animations","Balance settings","Play","Collection","Archive / new egg","Toys / accessories","Museum","Reset scenario","Bedtime","Feedback test","Set time"];
    var animationNames=["wander","hop","eat","sleep","clean","evolve","blink","look"];
    var messages=["HAPPY BEAST!","PATS: 3/3","ALL CLEAN!","ALL CLEAN","RESTING","FULL / NONE","REAL BEAST","TEST ITEMS","POOP TEST","CLEAN TEST","REST TEST","EVOLVE TEST","TEST RESET","TIME +","STAGE SET","FAMILY TEST","CUE TEST","RARE FORM!","BE A LEGEND","TRY TRAIL","NEW JOURNEY","BEAST KEPT","BOND: 70","NEED CHARM"];
    var menuCounts=[];var menuTotal=0;var sceneCount=0;
    function finishExit() as Void {System.exit();}
    function initialize(){
        TekuTekuBeastView.initialize();beast=new ArtPreviewState();
        for(var i=0;i<menuNames.size();i++){openMenu(menuNames[i]);menuCounts.add(rows.size());menuTotal+=rows.size();}
        menu=null;sceneCount=165+menuTotal+3+18+messages.size()+12+270+25;
    }
    function sceneAt(index){
        if(index<165){
            var specimen=index/11;var part=index%11;
            return [specimen<3?specimen:3+(specimen-3)/4,specimen<3?0:1+(specimen-3)%4,
                part<3?part:0,null,0,part<3?"idle":animationNames[part-3],0];
        }
        index-=165;
        for(var i=0;i<menuCounts.size();i++){
            if(index<menuCounts[i]){return [1,0,0,menuNames[i],index,"idle",0];}index-=menuCounts[i];
        }
        if(index<3){return [5,4,index,null,0,"idle",1];}index-=3;
        if(index<18){return [1,0,index/6,"GAME",index%6,"idle",0];}index-=18;
        if(index<messages.size()){return [1,0,0,null,0,"idle",0,messages[index]];}
        index-=messages.size();if(index<12){return [5,1+index/3,index%3,null,0,"idle",0,null,1];}
        index-=12;
        if(index<270){var specimen=(index/18).toNumber();
            return [specimen<3?specimen:3+(specimen-3)/4,specimen<3?0:1+(specimen-3)%4,0,null,0,"idle",0,null,0,index%18];}
        return [1,0,2,"TRAIL_CASE",index-270,"idle",0];
    }
    function onShow(){loadSprite();refresher=new Toybox.Timer.Timer();refresher.start(method(:refresh),50,true);}
    function refresh() as Void {WatchUi.requestUpdate();}
    function capture(box,value){boxes.add(box);if(!box[4].equals(value)){failures.add("Truncated: "+value+" at "+box[1]+" to "+box[4]);}}
    function label(dc,top,value,font){var box=TekuTekuBeastView.label(dc,top,value,font);capture(box,value);return box;}
    function checkScene(dc){
        var r=dc.getWidth()/2-8;var cx=dc.getWidth()/2;var cy=dc.getHeight()/2;
        for(var i=0;i<boxes.size();i++){
            var b=boxes[i];
            for(var c=0;c<4;c++){var x=b[0]+(c%2==0?0:b[2]);var top=b[1]+(c<2?0:b[3]);
                if((x-cx)*(x-cx)+(top-cy)*(top-cy)>r*r){failures.add("Circle: "+b[4]);}}
            for(var j=0;j<i;j++){var a=boxes[j];
                if(b[0]<a[0]+a[2] && b[0]+b[2]>a[0] && b[1]<a[1]+a[3] && b[1]+b[3]>a[1]){failures.add("Overlap: "+b[4]+" / "+a[4]);}}
        }
    }
    function runAudit(dc){
        var scene=sceneAt(cursor);var model=beast as ArtPreviewState;
        model.previewStage=scene[0];model.previewFamily=scene[1];model.stress=scene[6];
        model.data["rare"]=scene.size()>8?scene[8]:0;
        model.data["xp"]=scene[6]==1?2000000000l:325000l;
        model.data["fullness"]=100;model.data["friendship"]=100;model.data["snacks"]=12;
        model.data["sleepMode"]=2;model.data["sleepUntil"]=0l;model.data["energy"]=80;model.data["happiness"]=90;model.data["motion"]=2;model.data["poop"]=0;
        page=scene[2];animation=scene[5];animationTicks=12;tick=scene[5].equals("wander")?0:2;notice=scene.size()>7?scene[7]:null;
        if(scene.size()>9){
            var pose=scene[9];model.data["motion"]=(pose/6).toNumber();tick=(pose%6)*17;
            if(pose%6==1){model.data["energy"]=0;}
            if(pose%6==2){model.simulateSleep(true);}
            if(pose%6==3){model.data["fullness"]=20;model.data["happiness"]=20;model.data["poop"]=2;}
        }
        if(scene[3]!=null && scene[3].equals("TRAIL_CASE")){
            var trip=new AuditGame(beast,2,self);var variant=scene[4];trip.tick=12;
            trip.phase=variant==24?3:2;trip.result="SCOUT COMPLETE";
            if(variant<24){trip.trail=variant/6;trip.node=(variant/2)%3;trip.choice=variant%2;}
            boxes=[];trip.onUpdate(dc);checkGraphic(dc,trip.gameBounds,"Adventure creature");
        }else if(scene[3]!=null && scene[3].equals("GAME")){
            var game=new AuditGame(beast,page,self);game.phase=scene[4];game.sequence=[0,1,2,0,1];game.result="WELL PLAYED!";
            game.hint="GREAT!";game.lane=scene[4]==1?0:2;game.jumpTicks=4;game.tick=12;
            boxes=[];game.onUpdate(dc);
            checkGraphic(dc,game.gameBounds,"Game creature");
        }else{
            if(scene[3]!=null){openMenu(scene[3]);selection=scene[4];}else{menu=null;}
            loadSprite();boxes=[];TekuTekuBeastView.onUpdate(dc);
        }
        var stats=System.getSystemStats();if(stats.usedMemory>peakMemory){peakMemory=stats.usedMemory;}totalMemory=stats.totalMemory;
        checkScene(dc);cursor++;
        if(page==0 && scene[3]==null){
            var radius=dc.getWidth()/2-8;var cx=dc.getWidth()/2;var cy=dc.getHeight()/2;
            for(var corner=0;corner<4;corner++){
                var px=petBounds[0]+(corner%2==0?0:petBounds[2]);var py=petBounds[1]+(corner<2?0:petBounds[3]);
                if((px-cx)*(px-cx)+(py-cy)*(py-cy)>radius*radius){failures.add("Sprite circle: "+beast.speciesName());}
            }
            if(petBounds[1]+petBounds[3]>y(dc,0.76)){failures.add("Sprite footer collision");}
        }
        if(cursor>=sceneCount){
            audited=true;refresher.stop();System.println("LAYOUT_AUDIT: "+cursor+" scenes; "+failures.size()+" failures");
            System.println("LAYOUT_MEMORY: peak="+peakMemory+" total="+totalMemory);
            for(var i=0;i<failures.size();i++){System.println(failures[i]);}WatchUi.requestUpdate();
        }
    }
    function checkGraphic(dc,bounds,name){
        var radius=dc.getWidth()/2-8;
        for(var corner=0;corner<4;corner++){
            var px=bounds[0]+(corner%2==0?0:bounds[2]);var py=bounds[1]+(corner<2?0:bounds[3]);
            if((px-dc.getWidth()/2)*(px-dc.getWidth()/2)+(py-dc.getHeight()/2)*(py-dc.getHeight()/2)>radius*radius){failures.add(name+" circle");}
        }
    }
    function onUpdate(dc){
        if(!audited){runAudit(dc);return;}
        if(!showSummary){TekuTekuBeastView.onUpdate(dc);return;}
        dc.setColor(BG,BG);dc.clear();boxes=[];
        label(dc,y(dc,0.18),"ROUND LAYOUT AUDIT",Graphics.FONT_XTINY);
        label(dc,y(dc,0.35),failures.size()==0?"PASS":"FAIL",Graphics.FONT_LARGE);
        label(dc,y(dc,0.58),cursor+" SCENES",Graphics.FONT_XTINY);
        label(dc,y(dc,0.72),failures.size()+" OVERLAPS / CLIPS",Graphics.FONT_XTINY);
        if(exitWhenDone && !exitScheduled){exitScheduled=true;refresher.start(method(:finishExit),1000,false);}
    }
}
(:background)
class ArtPreviewApp extends Application.AppBase {
    function initialize(){AppBase.initialize();}
    function getInitialView(){var view=new ArtLayoutAuditView();return [view,new TekuTekuBeastInput(view)];}
}
