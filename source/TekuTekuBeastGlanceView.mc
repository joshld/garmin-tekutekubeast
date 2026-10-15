using Toybox.Application.Storage;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;

// This entry point only reads the real cached save. No State, clock, timers,
// feedback, migration or inventory writes are reachable from the glance.
(:glance)
class TekuTekuBeastGlanceView extends WatchUi.GlanceView {
    var snapshot as Lang.Dictionary or Null=null;var sprite=null;var cachedId=-1;
    function initialize(){GlanceView.initialize();}
    function onShow(){
        readSummary();
    }
    function readSummary(){
        snapshot=Storage.getValue("v4") as Lang.Dictionary or Null;
        var ids=[Rez.Drawables.V4EggSmall,Rez.Drawables.V4PipSmall,Rez.Drawables.V4NimbleSmall,Rez.Drawables.V4Grove3Small,Rez.Drawables.V4Grove4Small,Rez.Drawables.V4Grove5Small,Rez.Drawables.V4Ember3Small,Rez.Drawables.V4Ember4Small,Rez.Drawables.V4Ember5Small,Rez.Drawables.V4Tide3Small,Rez.Drawables.V4Tide4Small,Rez.Drawables.V4Tide5Small,Rez.Drawables.V4Wisp3Small,Rez.Drawables.V4Wisp4Small,Rez.Drawables.V4Wisp5Small];
        var index=0;
        if(snapshot!=null && snapshot.hasKey("cachedSprite")){index=snapshot["cachedSprite"] as Lang.Number;}
        if(index<0 || index>=ids.size()){index=0;}
        if(index!=cachedId){sprite=WatchUi.loadResource(ids[index]);cachedId=index;}
    }
    function onUpdate(dc){
        readSummary();
        dc.setColor(0xFFFFFF,0x000000);dc.clear();
        if(sprite!=null){dc.drawBitmap(4,(dc.getHeight()-40)/2,sprite);}
        var name="EGG";var mood="OPEN GAME";var progress=0.0;
        if(snapshot!=null && snapshot.hasKey("cachedName")){
            name=snapshot["cachedName"];mood=snapshot["cachedMood"];progress=snapshot["cachedProgress"];
            if(snapshot["poop"]>0){mood="CLEANUP";}
        }
        var font=Graphics.FONT_XTINY;var left=50;var width=dc.getWidth()-left-48;
        var lines=[name];var split=name.find(" ");
        if(dc.getTextWidthInPixels(name,font)>width && split!=null){
            lines=[name.substring(0,split),name.substring(split+1,name.length())];
        }
        for(var i=0;i<lines.size();i++){
            while(lines[i].length()>0 && dc.getTextWidthInPixels(lines[i],font)>width){lines[i]=lines[i].substring(0,lines[i].length()-1);}
        }
        while(mood.length()>0 && dc.getTextWidthInPixels(mood,font)>width){mood=mood.substring(0,mood.length()-1);}
        var row=dc.getFontHeight(font);var top=((dc.getHeight()-8-row*(lines.size()+1))/2).toNumber();
        if(top<0){top=0;}
        for(var j=0;j<lines.size();j++){dc.drawText(left,top+row*j,font,lines[j],Graphics.TEXT_JUSTIFY_LEFT);}
        dc.drawText(left,top+row*lines.size(),font,mood,Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(0x55AA55,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(left,dc.getHeight()-8,(width*progress).toNumber(),4);
    }
}
