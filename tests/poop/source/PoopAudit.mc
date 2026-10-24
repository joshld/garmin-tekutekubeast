using Toybox.WatchUi;
using Toybox.System;
using Toybox.Application.Storage;

// QA UUID only; namespace never reads/writes production pet or activity data.
class PoopQAStore extends BeastStore {
    function initialize(){
        BeastStore.initialize();memory={};
        memory["v4"]=Storage.getValue("qa.poop24.v4");
        memory["glance.v1"]=Storage.getValue("qa.poop24.glance.v1");
        memory["clock"]=Storage.getValue("qa.poop24.clock");
    }
    function write(key,value){
        var changed=BeastStore.write(key,value);
        if(changed){Storage.setValue("qa.poop24."+key,value);}return changed;
    }
}
class PoopQAState extends TekuTekuBeastState {
    function initialize(){
        TekuTekuBeastState.initialize();store=new PoopQAStore();skipWatch=true;
        var clock=store.read("clock");testNow=clock==null?1792108800l:clock+14400;start();
        if(clock==null){data["stageFloor"]=2;data["sleepMode"]=2;data["sound"]=0;data["haptics"]=0;testNow+=20*3600;}
        tick();commit();
        System.println("POOP_REOPEN: count="+number("poop")+" slots="+poopMask()+" cleanliness="+number("cleanliness"));
    }
    function commit(){TekuTekuBeastState.commit();if(!dev){store.write("clock",now());}}
    function syncHistory(){start();tick();commit();}
    function getTodaySteps(){return 0;}
}
(:background,:glance)
class MatrixApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){var v=new PoopAudit();return [v,new TekuTekuBeastInput(v)];}
}
class PoopAudit extends TekuTekuBeastView {
    var cursor=0;var failures=0;var peak=0;var auditing=true;
    function initialize(){TekuTekuBeastView.initialize();beast=new ArtPreviewState();ensureWorld();}
    function onShow(){
        if(!auditing){TekuTekuBeastView.onShow();return;}
        refresher=new Toybox.Timer.Timer();refresher.start(method(:refresh),50,true);
    }
    function refresh() as Void {if(auditing){WatchUi.requestUpdate();}else{TekuTekuBeastView.refresh();}}
    function switchPage(delta){
        if(!auditing && menu==null && page==0 && delta==1){
            beast.testNow+=14400;beast.tick();beast.commit();notice="+4H: "+beast.number("poop")+" POOPS";noticeTicks=12;
            System.println("POOP_ADVANCE: count="+beast.number("poop")+" slots="+beast.poopMask());WatchUi.requestUpdate();return;
        }
        TekuTekuBeastView.switchPage(delta);
    }
    function selectAction(){
        if(auditing){return;}
        TekuTekuBeastView.selectAction();
        System.println("POOP_ACTION: count="+beast.number("poop")+" slots="+beast.poopMask()+" cleanliness="+beast.number("cleanliness")+" care="+beast.number("careGrowth")+" friendship="+beast.friendship());
    }
    function onUpdate(dc){
        if(!auditing){TekuTekuBeastView.onUpdate(dc);return;}
        var model=beast as ArtPreviewState;model.previewStage=cursor%2==0?1:2;
        model.data["sleepMode"]=2;model.data["energy"]=80;model.data["happiness"]=80;
        model.data["poop"]=(cursor/16).toNumber();model.repairPoop();
        var theme=((cursor%16)/4).toNumber();var night=cursor%4<2;
        loadSprite();roamTicks=((cursor%8)*48+31).toFloat();tick=roamTicks.toNumber();
        sky=night?[3,0.25,false]:[1,0.5,true];darkScene=night;
        scenery.draw(dc,theme,sky,false);creature(dc);drawPoop(dc);
        var count=0;var scale=poopScale(dc.getWidth());var top=poopTop(dc.getHeight());
        for(var slot=0;slot<5;slot++){
            if((beast.poopMask()&(1<<slot))==0){continue;}count++;
            var x=poopX(dc.getWidth(),slot);var bottom=top+6*scale;var mid=dc.getWidth()/2;
            if(top<=petBounds[1]+petBounds[3] || bottom>=y(dc,0.80)){failures++;}
            if(slot>0 && x<=poopX(dc.getWidth(),slot-1)+7*scale){failures++;}
            for(var edge=0;edge<4;edge++){
                var dx=x+(edge%2)*7*scale-mid;var dy=(edge<2?top:bottom)-mid;
                if(dx*dx+dy*dy>=(mid-9)*(mid-9)){failures++;}
            }
        }
        if(count!=beast.number("poop")){failures++;}
        var used=System.getSystemStats().usedMemory;if(used>peak){peak=used;}
        cursor++;
        if(cursor==96){
            System.println("POOP_LAYOUT: scenes="+cursor+" failures="+failures+" sampledHeap="+peak);
            refresher.stop();auditing=false;frames=null;sprite=null;spriteStage=-1;beast=new PoopQAState();
            world=null;scenery=null;TekuTekuBeastView.onShow();WatchUi.requestUpdate();
        }
    }
}
