using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

class FeedbackScene extends AuditGame {
    var chosenMask=0;
    function initialize(b,k,a){AuditGame.initialize(b,k,a);}
    function drawArrow(dc,x,top,move,chosen){
        if(chosen){chosenMask|=1<<move;}
        AuditGame.drawArrow(dc,x,top,move,chosen);
        owner.boxes.add([x-7,top-6,28,28,"Input "+move]);
    }
}
// RAM-only fixtures and the existing isolated QA identity. No system alerts,
// DND settings, actual watch activity, real pet saves or session rewards.
class FeedbackAudit extends ArtLayoutAuditView {
    function initialize(){TekuTekuBeastView.initialize();beast=new ArtPreviewState();sceneCount=55;}
    function onShow(){
        if(!audited){refresher=new Toybox.Timer.Timer();refresher.start(method(:refresh),70,true);}
    }
    function selectAction(){
        audited=true;if(refresher!=null){refresher.stop();refresher=null;}
        var view=new FeedbackMenu();WatchUi.pushView(view,new TekuTekuBeastInput(view),WatchUi.SLIDE_LEFT);
    }
    function back(){System.exit();return true;}
    function onUpdate(dc){
        if(audited){
            dc.setColor(BG,BG);dc.clear();
            label(dc,y(dc,0.25),"INPUT / PAUSE QA",Graphics.FONT_XTINY);
            label(dc,y(dc,0.43),failures.size()==0?"PASS":"FAIL",Graphics.FONT_LARGE);
            label(dc,y(dc,0.64),"SELECT: PLAY",Graphics.FONT_XTINY);return;
        }
        var model=beast as ArtPreviewState;model.previewStage=2;model.data["sleepMode"]=2;model.data["sleepUntil"]=0l;
        model.data["haptics"]=0;model.data["energy"]=80;model.data["motion"]=2;
        var kind=cursor>=44?(cursor>=53?2:((cursor-44)/3).toNumber()):(cursor<26?1:(cursor<32?((cursor-26)/2).toNumber():(cursor<43?((cursor-32)/4).toNumber():1)));
        var game=new FeedbackScene(beast,kind,self);game.sequence=[0,0,1,2];game.phase=2;game.hint="GREAT!";
        var expectedMask=-1;
        if(cursor>=44){
            game.session=model.beginSession(kind);game.paused=true;
            game.pauseOptions.choice=cursor>=53?cursor-53:(cursor-44)%3;
            game.pauseOptions.confirming=cursor>=53;
        }else if(cursor<12){
            game.expectedMove=(cursor/4).toNumber();game.registeredMove=cursor%4-1;
            game.phase=game.expectedMove==game.registeredMove?2:4;game.inputTicks=2;
            expectedMask=game.registeredMove<0?0:1<<game.registeredMove;
        }else if(cursor<18){
            game.registeredMove=((cursor-12)/2).toNumber();game.expectedMove=game.registeredMove;
            game.cursor=1+cursor%2;game.inputTicks=2;expectedMask=1<<game.registeredMove;
        }else if(cursor<26){
            var step=cursor-18;game.phase=1;game.elapsed=(step/2).toNumber()*(game.tempo()+game.cueGap())+(step%2==1?game.tempo():0);
            expectedMask=step%2==1?0:1<<game.sequence[(step/2).toNumber()];
        }else if(cursor<32){
            game.phase=kind==0?1:(kind==1?2:5);game.session=model.beginSession(kind);
            game.paused=cursor%2==0;game.resumeTicks=game.paused?0:2;
        }else if(cursor<43){
            var part=(cursor-32)%4;game.phase=part==0?0:(part==1?(kind==2?5:1):(part==2?3:2));
            game.result="WELL PLAYED!";game.tick=0;game.cursor=0;
        }else{game.phase=4;game.hint="TRY AGAIN";} // pre-feedback session
        boxes=[];game.onUpdate(dc);checkScene(dc);if(!game.paused){checkGraphic(dc,game.gameBounds,"Game creature");}
        if(expectedMask>=0 && game.chosenMask!=expectedMask){failures.add("Registered arrow mismatch "+cursor);}
        var stats=System.getSystemStats();if(stats.usedMemory>peakMemory){peakMemory=stats.usedMemory;}
        cursor++;
        if(cursor==sceneCount){
            audited=true;refresher.stop();
            System.println("GAME_FEEDBACK_LAYOUT: "+cursor+" scenes; "+failures.size()+" failures; sampledHeap="+peakMemory+"/"+stats.totalMemory);
            for(var i=0;i<failures.size();i++){System.println(failures[i]);}
            refresher.start(method(:finishExit),30000,false);WatchUi.requestUpdate();
        }
    }
}
