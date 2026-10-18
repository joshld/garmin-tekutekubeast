using Toybox.WatchUi;
using Toybox.System;

// SDK-only RAM fixture, isolated matrix UUID. No real pet, GPS or save writes.
// After audit: SELECT previews/toggles ON/OFF; UP/DOWN change theme; BACK sky.
class LightingAudit extends ArtLayoutAuditView {
    var previewing=false;var themeIndex=0;var oldX=0;var oldY=0;var oldLayer=null;
    function initialize(){ArtLayoutAuditView.initialize();sceneCount=70;}
    function sceneAt(index){
        var state=beast as ArtPreviewState;state.data["autoLights"]=1;
        if(index<32){
            var theme=(index/8).toNumber();var phase=((index%8)/2).toNumber();
            state.setLighting(index%2==0?1:2);
            return [1,theme+1,0,"WORLD_CASE",phase*16,"idle",0];
        }
        index-=32;
        if(index<30){state.data["autoLights"]=(index/15).toNumber();state.setLighting(((index%15)/5).toNumber());
            return [1,0,0,"Lighting",index%5,"idle",0];}
        index-=30;if(index<3){state.setLighting(index);return [1,0,0,"Actions",7,"idle",0];}
        state.setLighting(0);return [1,0,0,"Bedtime",index-3,"idle",0];
    }
    function runAudit(dc){
        var index=cursor;ArtLayoutAuditView.runAudit(dc);
        if(index<32){
            var phase=((index%8)/2).toNumber();
            if(sky[0]!=phase){failures.add("Lighting changed sky phase");}
            if(index%2==1){
                if(scenery.celestialX!=oldX || scenery.celestialY!=oldY){failures.add("Lighting moved sky object");}
                if(phase==3 && scenery.layer!=oldLayer){failures.add("Night switch reloaded terrain");}
            }
            oldX=scenery.celestialX;oldY=scenery.celestialY;oldLayer=scenery.layer;
        }
        if(audited){System.println("LIGHTING_AUDIT: 32 theme/phase/manual scenes; 38 menu rows; failures="+failures.size());}
    }
    function preparePreview(){
        var state=beast as ArtPreviewState;state.previewStage=1;state.previewFamily=0;
        state.data["motion"]=0;state.data["sleepMode"]=2;state.data["sleepUntil"]=0l;
        state.data["energy"]=80;state.data["poop"]=1;state.data["fullness"]=20;state.data["happiness"]=20;
        ensureWorld();world.setTheme(themeIndex+1);menu=null;page=0;notice=null;animation="idle";animationTicks=0;
        showSummary=false;loadSprite();WatchUi.requestUpdate();
    }
    function selectAction(){
        if(!audited){return;}if(!previewing){previewing=true;world.preview=3;beast.setLighting(1);}
        else{beast.setLighting(beast.isDark()?1:2);}preparePreview();
    }
    function switchPage(delta){if(previewing){themeIndex=(themeIndex+delta+4)%4;preparePreview();}}
    function back(){if(previewing){world.preview=(world.preview+1)%4;world.invalidate();preparePreview();}return true;}
}
(:background,:glance)
class MatrixApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){var v=new LightingAudit();return [v,new TekuTekuBeastInput(v)];}
}
