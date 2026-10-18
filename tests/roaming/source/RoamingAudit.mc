using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

// Isolated QA UUID and RAM pet. SELECT advances a frozen production pose;
// UP/DOWN changes pose, BACK switches day/night. Never touches the real pet.
(:background,:glance)
class MatrixApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){var v=new RoamingAudit();return [v,new TekuTekuBeastInput(v)];}
}
class RoamingAudit extends TekuTekuBeastView {
    var example=0;var night=true;
    var auditing=true;var cursor=0;var failures=0;var peak=0;var autoExit=true;
    var moments=[0,1,7,31,32,45];
    var poses=[49,50,97,98,1,2,31,32,41,42,45,46];
    function initialize(){TekuTekuBeastView.initialize();beast=new ArtPreviewState();ensureWorld();}
    function onShow(){loadSprite();refresher=new Toybox.Timer.Timer();refresher.start(method(:refresh),100,true);}
    function refresh() as Void {if(auditing){WatchUi.requestUpdate();}}
    function finish() as Void {System.exit();}
    function selectAction(){example=(example+1)%28;WatchUi.requestUpdate();}
    function switchPage(delta){example=(example+delta+28)%28;WatchUi.requestUpdate();}
    function back(){night=!night;WatchUi.requestUpdate();return true;}
    function onUpdate(dc){
        if(auditing){auditScene(dc);return;}
        var model=beast as ArtPreviewState;model.previewStage=example<12?2:1;model.previewFamily=0;
        model.data["sleepMode"]=2;model.data["sleepUntil"]=0l;model.data["energy"]=80;
        model.data["fullness"]=80;model.data["happiness"]=80;model.data["motion"]=2;
        model.data["poop"]=0;model.data["lightingMode"]=1;
        menu=null;page=0;animation="idle";animationTicks=0;notice=null;
        roamTicks=poses[example%12].toFloat();tick=poses[example%12];
        loadSprite();sky=night?[3,0.05,false]:[1,0.5,true];sceneInk=night?0xAAFFAA:INK;
        scenery.draw(dc,example>=24?example-24:0,sky,false);
        if(example<24){creature(dc);}
        label(dc,y(dc,0.84),(example<12?"NIMBLE":"PIP")+" "+tick+" F"+petFrame,Graphics.FONT_XTINY);
        System.println("ROAM_PREVIEW: scene="+example+" stride="+tick+" frame="+petFrame+" bounds="+petBounds+" heap="+System.getSystemStats().usedMemory);
    }
    function auditScene(dc){
        var model=beast as ArtPreviewState;
        model.previewStage=cursor<96?2:1;model.previewFamily=0;
        model.data["sleepMode"]=2;model.data["sleepUntil"]=0l;model.data["energy"]=80;
        model.data["fullness"]=80;model.data["poop"]=0;
        model.data["happiness"]=cursor%4<2?90:80;model.data["motion"]=cursor%2+1;
        var point=((cursor%96)/2).toNumber();var part=(point/6).toNumber();var p=moments[point%6];
        roamTicks=(part*48+p).toFloat();tick=roamTicks.toNumber();
        animation="idle";animationTicks=0;loadSprite();
        sky=cursor%2==0?[3,0.05,false]:[1,0.5,true];
        scenery.draw(dc,part%4,sky,false);creature(dc);
        var r=dc.getWidth()/2-8;var mid=dc.getWidth()/2;
        for(var corner=0;corner<4;corner++){
            var x=petBounds[0]+(corner%2==0?0:petBounds[2]);
            var y=petBounds[1]+(corner<2?0:petBounds[3]);
            if((x-mid)*(x-mid)+(y-mid)*(y-mid)>r*r){failures++;}
        }
        if(p<32){
            var before=(part+7)%8;var from=tick<48?roamOriginX:roamX[before];
            var expected=BeastArt.walkFrame(model.stage(),0,tick%2,roamX[part]<from);
            if(petFrame!=expected){failures++;System.println("DIRECTION FAIL "+cursor);}
        }
        if(petBounds[1]+petBounds[3]>dc.getHeight()*0.76){failures++;}
        var stats=System.getSystemStats();if(stats.usedMemory>peak){peak=stats.usedMemory;}
        cursor++;
        if(cursor==192){
            auditing=false;refresher.stop();example=0;
            System.println("ROAM_AUDIT: scenes="+cursor+" failures="+failures+" sampledPeak="+peak+" total="+stats.totalMemory);
            if(autoExit){refresher.start(method(:finish),100,false);}else{WatchUi.requestUpdate();}
        }
    }
}
