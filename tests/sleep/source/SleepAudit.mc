using Toybox.WatchUi;
using Toybox.System;

// Enduro-only SDK fixture: RAM state and existing isolated matrix identity.
// After PASS, tap once for a sleeping beast; normal production actions follow.
class SleepAudit extends ArtLayoutAuditView {
    var previewing=false;
    function initialize(){ArtLayoutAuditView.initialize();sceneCount=62;}
    function specimen(index){
        var state=beast as ArtPreviewState;
        state.previewStage=index<3?index:3+((index-3)/4).toNumber();state.previewFamily=index<3?0:1+(index-3)%4;
    }
    function sleepingFixture(){
        beast.data["sleepMode"]=2;beast.data["sleepUntil"]=beast.now()+2400;
        beast.data["awakeAt"]=0l;beast.data["awakeUntil"]=0l;beast.data["grumpAt"]=0l;beast.data["grumpLevel"]=0;
        beast.data["energy"]=80;beast.data["fullness"]=40;beast.data["happiness"]=80;beast.data["poop"]=1;
        beast.data["motion"]=2;beast.data["lightsUntil"]=0l;
        ensureWorld();world.preview=3;page=0;menu=null;notice=null;animation="idle";animationTicks=0;
    }
    function runAudit(dc){
        sleepingFixture();specimen(1);tick=4;boxes=[];
        if(cursor<45){specimen((cursor/3).toNumber());if(cursor%3==1){beast.wakeUp();}if(cursor%3==2){beast.data["sleepUntil"]=0l;}}
        else if(cursor<55){openMenu("Actions");selection=cursor-45;}
        else if(cursor<57){notice=cursor==55?"Beast is asleep.":"Waking up.";if(cursor==56){beast.wakeUp();}}
        else if(cursor<60){
            var game=new AuditGame(beast,cursor-57,self);game.phase=3;game.result="Beast is asleep.";game.resultChoice=1;
            game.onUpdate(dc);checkGraphic(dc,game.gameBounds,"Paused sleeping game");
        }else{page=1;if(cursor==61){beast.wakeUp();}}
        if(cursor<57 || cursor>=60){loadSprite();TekuTekuBeastView.onUpdate(dc);if(page==0 && menu==null){checkGraphic(dc,petBounds,"Sleep/wake creature");}}
        checkScene(dc);var stats=System.getSystemStats();if(stats.usedMemory>peakMemory){peakMemory=stats.usedMemory;}
        cursor++;
        if(cursor>=sceneCount){
            audited=true;refresher.stop();System.println("SLEEP_LAYOUT: "+cursor+" scenes; "+failures.size()+" failures");
            System.println("SLEEP_MEMORY: peak="+peakMemory+" total="+stats.totalMemory);
            for(var i=0;i<failures.size();i++){System.println(failures[i]);}WatchUi.requestUpdate();
        }
    }
    function selectAction(){
        if(!audited){return;}
        if(!previewing){previewing=true;sleepingFixture();specimen(1);showSummary=false;loadSprite();WatchUi.requestUpdate();return;}
        TekuTekuBeastView.selectAction();
    }
    function refresh() as Void {if(audited){TekuTekuBeastView.refresh();}else{ArtLayoutAuditView.refresh();}}
}
(:background,:glance)
class MatrixApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){var v=new SleepAudit();return [v,new TekuTekuBeastInput(v)];}
}
