using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Application;

// Deliberately repeated first cues, in-memory QA beast, production game/input.
class RepeatedMemory extends BeastGameView {
    var lastMove=-99;var gapAt=0;
    function initialize(b){BeastGameView.initialize(b,1);}
    function makeSequence(){BeastGameView.makeSequence();sequence[0]=0;sequence[1]=0;}
    function refresh() as Void {
        BeastGameView.refresh();var move=displayedMove();
        if(phase==1 && move!=lastMove){
            var t=System.getTimer();if(move==-1){gapAt=t;}
            if(lastMove==-1 && move>=0){System.println("MEMORY_NEUTRAL_GAP: "+(t-gapAt)+"ms");}
            System.println("MEMORY_CUE: move="+move+" elapsedTicks="+elapsed);lastMove=move;
        }
    }
}
class TimedBounce extends BeastGameView {
    var starAt=0;
    function initialize(b){BeastGameView.initialize(b,0);}
    function begin(){BeastGameView.begin();starAt=System.getTimer();}
    function catchStar(check){
        var stage=round;BeastGameView.catchStar(check);
        if(!check){var t=System.getTimer();System.println("BOUNCE_STAR: stage="+(stage+1)+" durationMs="+(t-starAt)+" hits="+hits);starAt=t;}
    }
}
class FeedbackMenu extends WatchUi.View {
    var beast;var selection=0;var refresher=null;
    function initialize(){View.initialize();beast=new ArtPreviewState();beast.previewStage=1;beast.data["sleepMode"]=2;beast.data["sound"]=0;beast.data["haptics"]=0;}
    function onShow(){Application.getApp().activeView=self;}
    function onHide(){}
    function onUpdate(dc){dc.setColor(0x005500,0xAAFFAA);dc.clear();
        dc.drawText(dc.getWidth()/2,dc.getHeight()*.20,Graphics.FONT_XTINY,"GAME TIMING QA",Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth()/2,dc.getHeight()*.47,Graphics.FONT_XTINY,["REPEAT UP / UP","BOUNCE NORMAL","BOUNCE EASY"][selection],Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth()/2,dc.getHeight()*.72,Graphics.FONT_XTINY,"SELECT TO OPEN",Graphics.TEXT_JUSTIFY_CENTER);}
    function selectAction(){beast.data["easy"]=selection==2?1:0;
        var v=selection==0?new RepeatedMemory(beast):new TimedBounce(beast);
        WatchUi.pushView(v,new TekuTekuBeastInput(v),WatchUi.SLIDE_LEFT);}
    function switchPage(delta){selection=(selection+delta+3)%3;WatchUi.requestUpdate();}
    function back(){return false;}function touch(point){selectAction();}
}
(:background,:glance)
class MatrixApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){var v=new FeedbackMenu();return [v,new TekuTekuBeastInput(v)];}
}
