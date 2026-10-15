using Toybox.WatchUi;
using Toybox.System;

(:glance)
class GlanceAuditView extends TekuTekuBeastGlanceView {
    function initialize(){TekuTekuBeastGlanceView.initialize();}
    function readSummary(){
        if(snapshot!=null){return;}
        // Conservative synthetic save-sized payload; no writes to any app save.
        var padding=new [1600];for(var i=0;i<padding.size();i++){padding[i]=0;}
        snapshot={"cachedName"=>"ECLIPSE EIDOLON","cachedMood"=>"EXCITED","cachedProgress"=>0.8,"poop"=>2,"padding"=>padding};
        sprite=WatchUi.loadResource(Rez.Drawables.V4Wisp5Small);
    }
    function onUpdate(dc){
        TekuTekuBeastGlanceView.onUpdate(dc);
        var stats=System.getSystemStats();
        System.println("GLANCE_AUDIT: "+dc.getWidth()+"x"+dc.getHeight()+" used="+stats.usedMemory+" total="+stats.totalMemory);
        System.exit();
    }
}
(:background, :glance)
class GlanceAuditApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getGlanceView(){return [new GlanceAuditView()];}
}
