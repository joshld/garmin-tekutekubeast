using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;
using Toybox.WatchUi;

// Isolated matrix identity, RAM-only saves. Instrumentation is never part of a
// production build. Sampled heap is a lower bound, not allocator-wide peak/RSS.
class AllocationStore extends BeastStore {
    var depth=0;var roots=0;var containers=0;var sampledPeak=0;
    function initialize(){BeastStore.initialize();memory={};}
    function reset(){roots=0;containers=0;sampledPeak=System.getSystemStats().usedMemory;}
    function copy(value){
        if(depth==0){roots++;}depth++;
        if(value instanceof Lang.Dictionary || value instanceof Lang.Array){containers++;}
        var result=BeastStore.copy(value);depth--;
        if(depth==0){var used=System.getSystemStats().usedMemory;if(used>sampledPeak){sampledPeak=used;}}
        return result;
    }
}

class ResourceAudit extends WatchUi.View {
    var timer=null;var stage=0;var frame=0;var view=null;var model=null;
    var peak=0;var total=0;var renderMs=0;var initial=null;
    var bench=null;var benchStore=null;var samples=0;var writes=0;var workMs=0;
    function initialize(){View.initialize();}
    function fixture(){
        var s=new ArtPreviewState();s.previewStage=5;s.previewFamily=4;
        s.data["sleepMode"]=2;s.data["sleepUntil"]=0l;s.data["motion"]=2;
        s.data["friendship"]=85;s.data["energy"]=80;s.data["happiness"]=90;
        return s;
    }
    function onShow(){timer=new Timer.Timer();timer.start(method(:advance),150,true);}
    function onHide(){if(timer!=null){timer.stop();timer=null;}}
    function advance() as Void {WatchUi.requestUpdate();}
    function transactions(){
        if(bench==null){
            var s=fixture();s.dev=false;s.store=new AllocationStore();s.battleData=null;
            bench=new BeastBattle(s);bench.beginBattle();benchStore=s.store;
            benchStore.reset();writes=benchStore.writes;
        }
        var start=System.getTimer();if(stage==5){bench.data["xp"]++;}bench.commit();workMs+=System.getTimer()-start;samples++;
        if(samples==(stage==5?30:100)){
            System.println("RESOURCE_COMMITS "+(stage==5?"changed=30":"unchanged=100")+" roots="+benchStore.roots+" containers="+benchStore.containers+" writes="+(benchStore.writes-writes)+" sampledPeak="+benchStore.sampledPeak+" ms="+workMs);
            samples=0;workMs=0;stage++;benchStore.reset();writes=benchStore.writes;
        }
    }
    function idleGames(){
        if(samples==0){view=new BeastGameView(fixture(),stage-7);view.timerPeriod=1000;}
        view.refresh();samples++;
        if(samples==30){
            System.println("RESOURCE_IDLE kind="+(stage-7)+" callbacks=30 redraws="+view.gameRedraws+" timer="+view.desiredGamePeriod()+" hiddenTimer="+(view.refresher!=null));
            view=null;samples=0;stage++;
        }
    }
    function beginScene(){
        model=fixture();peak=0;renderMs=0;frame=0;
        if(stage==0){view=new TekuTekuBeastView();view.beast=model;view.loadSprite();}
        else if(stage<4){view=new BeastGameView(model,stage-1);view.loadSprite();}
        else{
            view=new BeastBattleView(model);view.battle=view.fight.beginBattle();view.battlePhase=1;view.loadBattleArt();
        }
        initial=stage==4?view.battlePictures:view.frames;
    }
    function onUpdate(dc){
        if(stage==10){timer.stop();System.println("RESOURCE_AUDIT COMPLETE");System.exit();return;}
        if(stage==5 || stage==6){transactions();return;}
        if(stage>=7){idleGames();return;}
        if(frame==0){beginScene();}
        var start=System.getTimer();view.onUpdate(dc);renderMs+=System.getTimer()-start;
        var stats=System.getSystemStats();if(stats.usedMemory>peak){peak=stats.usedMemory;}total=stats.totalMemory;
        frame++;
        if(frame==12){
            var stable=stage==4?view.battlePictures==initial:view.frames==initial;
            System.println("RESOURCE_RENDER scene="+stage+" frames="+frame+" sampledPeak="+peak+" total="+total+" renderMs="+renderMs+" stableSprites="+stable);
            view.onHide();view=null;model=null;initial=null;stage++;frame=0;
        }
    }
}

(:background,:glance)
class MatrixApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){return [new ResourceAudit()];}
}
