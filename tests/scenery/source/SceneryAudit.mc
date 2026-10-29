using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics;

(:background,:glance)
class MatrixApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){var v=new SceneryAudit();return [v,new TekuTekuBeastInput(v)];}
}
// Isolated QA UUID, RAM/DEV only. Production scenery, Pet renderer and menus.
// After the audit: choose a real Environment row; BACK on Pet reopens that
// menu. On Pet, UP cycles sky previews, DOWN toggles lighting. No real GPS.
class SceneryAudit extends TekuTekuBeastView {
    var auditing=true;var cursor=0;var failures=0;var peak=0;var autoExit=true;
    function initialize(){TekuTekuBeastView.initialize();beast=new ArtPreviewState();ensureWorld();scenery.audit=true;}
    function onShow(){refresher=new Toybox.Timer.Timer();refresher.start(method(:refresh),100,true);}
    function refresh() as Void {if(auditing){WatchUi.requestUpdate();}else{TekuTekuBeastView.refresh();}}
    function back(){if(menu==null){openMenu("Environment");selection=7;WatchUi.requestUpdate();return true;}return TekuTekuBeastView.back();}
    function switchPage(delta){
        if(menu==null){
            if(delta<0){world.preview=(world.preview+1)%4;world.invalidate();}
            else{beast.setLighting(beast.isDark()?1:2);}
            WatchUi.requestUpdate();return;
        }
        TekuTekuBeastView.switchPage(delta);
    }
    function selectAction(){
        TekuTekuBeastView.selectAction();
        System.println("WORLD_MENU: selected="+world.environmentName()+" theme="+world.choose(beast.family(),beast.today())+" phase="+world.preview);
    }
    function label(dc,top,value,font){
        var box=TekuTekuBeastView.label(dc,top,value,font);
        if(auditing && menu!=null && menu.equals("Environment") && value.equals(rows[selection]) && !box[4].equals(value)){failures++;}
        return box;
    }
    function onUpdate(dc){
        if(!auditing){TekuTekuBeastView.onUpdate(dc);return;}
        var model=beast as ArtPreviewState;
        var landscapes=BeastWorld.THEME_COUNT*32;var total=landscapes+BeastWorld.THEME_COUNT+2;
        if(cursor>=landscapes){
            openMenu("Environment");selection=cursor-landscapes;TekuTekuBeastView.onUpdate(dc);
            cursor++;if(cursor==total){finishAudit();}return;
        }
        var theme=(cursor/32).toNumber();var phase=((cursor%32)/8).toNumber();
        model.previewStage=cursor%2==0?1:2;model.data["motion"]=2;model.data["sleepMode"]=2;
        model.data["energy"]=80;model.data["fullness"]=80;model.data["happiness"]=80;
        model.data["poop"]=cursor%4<2?0:5;model.repairPoop();model.setLighting(cursor%8<4?1:2);
        world.setTheme(theme+1);world.preview=phase;world.invalidate();menu=null;page=0;
        loadSprite();roamTicks=((cursor%8)*48+31).toFloat();tick=roamTicks.toNumber();
        drawPet(dc);var held=scenery.layer;drawPet(dc);
        if(scenery.layer!=held || sky[0]!=phase || scenery.layerKey!=theme*4+(beast.isDark()?3:phase)){failures++;}
        var scale=poopScale(dc.getWidth());var top=poopTop(dc.getHeight());
        if(petBounds[1]+petBounds[3]>=top || top+6*scale>=y(dc,0.80)){failures++;}
        for(var slot=0;slot<5;slot++){
            if(slot>0 && poopX(dc.getWidth(),slot)<=poopX(dc.getWidth(),slot-1)+7*scale){failures++;}
        }
        var used=System.getSystemStats().usedMemory;if(used>peak){peak=used;}
        cursor++;
    }
    function finishAudit(){
        System.println("WORLD_LAYOUT: scenes="+cursor+" failures="+failures+" sampledHeap="+peak+" total="+System.getSystemStats().totalMemory);
        if(autoExit){System.exit();return;}
        auditing=false;refresher.stop();var model=beast as ArtPreviewState;
        model.previewStage=2;model.data["poop"]=5;model.repairPoop();model.setLighting(1);
        world.preview=1;world.invalidate();world.setTheme(7);loadSprite();openMenu("Environment");selection=7;
        refresher=new Toybox.Timer.Timer();timerPeriod=1000;refresher.start(method(:refresh),1000,true);WatchUi.requestUpdate();
    }
}
