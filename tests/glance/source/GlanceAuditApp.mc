using Toybox.WatchUi;
using Toybox.System;
using Toybox.Time;

// Exercise the actual production readSummary/mood/sprite path with a read-only
// injected snapshot. No timers, Storage writes or fake production save.
(:glance)
class GlanceAuditView extends TekuTekuBeastGlanceView {
    var failures=0;var payload=null;var scene=0;var peak=0;var total=0;
    function initialize(){TekuTekuBeastGlanceView.initialize();}
    function savedSummary(){
        if(payload==null){
            payload={"cachedName"=>"ECLIPSE EIDOLON","cachedMood"=>"STALE","cachedProgress"=>0.8,
                "cachedSprite"=>0,"poop"=>0,"energy"=>80,"fullness"=>80,"happiness"=>90,"friendship"=>80};
        }
        payload["cachedSprite"]=(scene/4).toNumber();payload["sleepMode"]=2;payload["energy"]=80;
        payload["poop"]=scene%2;payload["sleepUntil"]=0l;payload["lastCare"]=Time.now().value();
        if(scene%4==1){payload["energy"]=0;}
        if(scene%4==2){payload["sleepUntil"]=Time.now().value()+3600;}
        if(scene%4==3){
            payload["energy"]=0;payload["lastCare"]=Time.now().value()-12*3600;
            payload["sleepMode"]=0;payload["nextBed"]=Time.now().value()+18*3600;
            payload["nextWake"]=Time.now().value()+2*3600;payload["scheduleAt"]=Time.now().value();
        }
        return payload;
    }
    function onUpdate(dc){
        failures=0;peak=0;
        for(scene=0;scene<60;scene++){
            TekuTekuBeastGlanceView.onUpdate(dc);
            var expected=(scene/4).toNumber()+(scene%4==0?0:100);
            if(cachedId!=expected){failures++;}
            var stats=System.getSystemStats();if(stats.usedMemory>peak){peak=stats.usedMemory;}total=stats.totalMemory;
        }
        System.println("GLANCE_AUDIT: "+dc.getWidth()+"x"+dc.getHeight()+" used="+peak+" total="+total);
        System.println("GLANCE_LAYOUT: "+failures+" failures");
        System.println("GLANCE_SCENES: 60 awake/tired/nap/night");
    }
    function drawLine(dc,left,top,font,value){
        if(left<0 || top<0 || left+dc.getTextWidthInPixels(value,font)>dc.getWidth() || top+dc.getFontHeight(font)>dc.getHeight()-8){failures++;}
        TekuTekuBeastGlanceView.drawLine(dc,left,top,font,value);
    }
}
(:background, :glance)
class GlanceAuditApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getGlanceView(){return [new GlanceAuditView()];}
}
