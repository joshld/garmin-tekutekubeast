using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.System;
class UpdateAuditDc {
    var real;var width;var shapes=[];
    function initialize(dc,size){real=dc;width=size;}
    function getWidth(){return width;}function getHeight(){return width;}
    function getFontHeight(f){return real.getFontHeight(f);}
    function getTextWidthInPixels(t,f){return real.getTextWidthInPixels(t,f);}
    function setColor(a,b){real.setColor(a,b);}function clear(){real.clear();}
    function drawText(x,y,f,t,j){real.drawText(x,y,f,t,j);}
    function fillRoundedRectangle(x,y,w,h,r){shapes.add([x,y,w,h,"selected"]);real.fillRoundedRectangle(x,y,w,h,r);}
}
class UpdateAuditView extends TekuTekuBeastView {
    var cursor=0;var failures=[];var boxes=[];var clock;var peak=0;
    var versions=["0.7.1","0.10.0","1.0.0-beta.1","999.999.999-beta.99","9.9.9-WWWWWWWWWWWWWW","999999999.9999999.9"];
    function initialize(){TekuTekuBeastView.initialize();beast=new ArtPreviewState();}
    function onShow(){clock=new Toybox.Timer.Timer();clock.start(method(:redraw),80,true);}
    function onHide(){if(clock!=null){clock.stop();}}
    function redraw() as Void {WatchUi.requestUpdate();}
    function label(dc,y,text,font){var b=TekuTekuBeastView.label(dc,y,text,font);if(!b[4].equals(text)){failures.add("truncated "+cursor+": "+text);}boxes.add(b);return b;}
    function onUpdate(dc){
        boxes=[];var size=dc.getWidth()<280 && cursor>=12?218:dc.getWidth();var target=new UpdateAuditDc(dc,size);
        var prompt=new BeastUpdatePrompt(versions[(cursor/2).toNumber()%versions.size()]);prompt.choice=cursor%2;prompt.draw(self,target);
        var all=[];for(var i=0;i<boxes.size();i++){all.add(boxes[i]);}for(var j=0;j<target.shapes.size();j++){all.add(target.shapes[j]);}
        var radius=size/2-8;
        for(var a=0;a<all.size();a++){
            var b=all[a];for(var c=0;c<4;c++){var x=b[0]+(c%2==0?0:b[2])-size/2;var y=b[1]+(c<2?0:b[3])-size/2;if(x*x+y*y>radius*radius){failures.add("circle "+cursor+": "+b[4]);break;}}
        }
        for(var m=0;m<boxes.size();m++){for(var n=0;n<m;n++){var b=boxes[m];var a=boxes[n];if(b[0]<a[0]+a[2] && b[0]+b[2]>a[0] && b[1]<a[1]+a[3] && b[1]+b[3]>a[1]){failures.add("overlap "+cursor+": "+b[4]);}}}
        peak=beast.max(peak,System.getSystemStats().usedMemory);cursor++;
        if(cursor>=(dc.getWidth()<280?24:12)){
            clock.stop();System.println("UPDATE_LAYOUT: scenes="+cursor+" failures="+failures.size()+" sampledHeap="+peak);
            for(var f=0;f<beast.min(15,failures.size());f++){System.println(failures[f]);}clock.start(method(:finish),100,false);
        }
    }
    function finish() as Void {System.exit();}
}
(:background,:glance)
class UpdateAuditApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){return [new UpdateAuditView()];}
}
class UpdateNetworkCheck extends BeastUpdates {
    function initialize(store,ready){BeastUpdates.initialize(store,"0.0.0","stable",ready);}
    function received(code,data) as Void {
        System.println("UPDATE_NETWORK_RESPONSE code="+code+" dictionary="+(data instanceof Toybox.Lang.Dictionary));
        BeastUpdates.received(code,data);if(code!=200 || BeastUpdateRules.release(data,"stable")==null){System.println("UPDATE_NETWORK_NOT_VERIFIED");System.exit();}
    }
}
class UpdateNetworkView extends WatchUi.View {
    var updates;var timer;
    function initialize(){View.initialize();}
    function onShow(){
        var store=new BeastStore();store.memory={};updates=new UpdateNetworkCheck(store,method(:ready));
        System.println("UPDATE_NETWORK_BEGIN: "+updates.URL);timer=new Toybox.Timer.Timer();timer.start(method(:timeout),30000,false);updates.start(Toybox.Time.now().value().toLong());
    }
    function ready(){System.println("UPDATE_NETWORK_OK available="+updates.state["available"]);timer.stop();System.exit();}
    function timeout() as Void {System.println("UPDATE_NETWORK_TIMEOUT");System.exit();}
    function onHide(){if(timer!=null){timer.stop();}}
    function onUpdate(dc){dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);dc.clear();}
}
(:background,:glance)
class UpdateNetworkApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){return [new UpdateNetworkView()];}
}
