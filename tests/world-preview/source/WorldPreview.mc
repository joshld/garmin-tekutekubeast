using Toybox.WatchUi;
using Toybox.System;
// QA only; latest production renderer, in-memory model, never the real pet.
(:background, :glance)
class MatrixApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){var v=new WorldPreview();return [v,new TekuTekuBeastInput(v)];}
}
class WorldPreview extends TekuTekuBeastView {
    var example=1;
    function initialize(){TekuTekuBeastView.initialize();beast=new ArtPreviewState();beast.previewStage=1;
        beast.data["sleepMode"]=2;beast.data["motion"]=0;beast.data["poop"]=0;beast.data["fullness"]=80;beast.data["happiness"]=80;
        ensureWorld();scenery.audit=true;world.preview=1;world.setTheme(1);}
    function onShow(){loadSprite();refresher=new Toybox.Timer.Timer();refresher.start(method(:refresh),1000,true);}
    function refresh() as Void {WatchUi.requestUpdate();}
    function switchPage(delta){example=(example+delta+18)%18;world.setTheme(example/4+1>4?1:example/4+1);world.preview=example%4;world.invalidate();WatchUi.requestUpdate();}
    function selectAction(){beast.data["motion"]=(beast.number("motion")+1)%3;WatchUi.requestUpdate();}
    function onUpdate(dc){
        if(example<16){TekuTekuBeastView.onUpdate(dc);}
        else{
            sceneInk=INK;dc.setColor(BG,BG);dc.clear();
            var bitmap=example==16?WatchUi.loadResource(Rez.Drawables.V4Pip0):WatchUi.loadResource(Rez.Drawables.HistoricalV050Pip);
            dc.drawBitmap(dc.getWidth()/2-bitmap.getWidth()/2,dc.getHeight()*0.70-bitmap.getHeight(),bitmap);
            label(dc,y(dc,0.83),example==16?"v0.4 PIXELS":"v0.5 PIXELS",Toybox.Graphics.FONT_XTINY);
        }
        if(scenery!=null){System.println("WORLD_RENDER: build="+scenery.buildMs+"ms cached="+scenery.cachedDrawMs+"ms memory="+System.getSystemStats().usedMemory);}
    }
}
