using Toybox.Application.Storage;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Time;

// This entry point only reads the real cached save. No State, growth advancement, timers,
// feedback, migration or inventory writes are reachable from the glance.
(:glance)
class TekuTekuBeastGlanceView extends WatchUi.GlanceView {
    var snapshot as Lang.Dictionary or Null=null;var sprite=null;var cachedId=-1;
    function initialize(){GlanceView.initialize();}
    // onUpdate follows onShow; avoid reading the same save twice on launch.
    function onShow(){}
    function readSummary(){
        snapshot=savedSummary();
        var ids=[Rez.Drawables.V4EggSmall,Rez.Drawables.V4PipSmall,Rez.Drawables.V4NimbleSmall,Rez.Drawables.V4Grove3Small,Rez.Drawables.V4Grove4Small,Rez.Drawables.V4Grove5Small,Rez.Drawables.V4Ember3Small,Rez.Drawables.V4Ember4Small,Rez.Drawables.V4Ember5Small,Rez.Drawables.V4Tide3Small,Rez.Drawables.V4Tide4Small,Rez.Drawables.V4Tide5Small,Rez.Drawables.V4Wisp3Small,Rez.Drawables.V4Wisp4Small,Rez.Drawables.V4Wisp5Small];
        var index=0;
        if(snapshot!=null && snapshot.hasKey("cachedSprite")){index=snapshot["cachedSprite"] as Lang.Number;}
        if(index<0 || index>=ids.size()){index=0;}
        var sleeping=snapshot!=null && (BeastSleep.sleeping(snapshot,Time.now().value()) || BeastSleep.forecastEnergy(snapshot,Time.now().value())<20);
        var key=index+(sleeping?100:0);
        if(key!=cachedId){
            if(sleeping){
                ids=[Rez.Drawables.V5EggSleepSmall,Rez.Drawables.V5PipSleepSmall,Rez.Drawables.V5NimbleSleepSmall,Rez.Drawables.V5Grove3SleepSmall,Rez.Drawables.V5Grove4SleepSmall,Rez.Drawables.V5Grove5SleepSmall,Rez.Drawables.V5Ember3SleepSmall,Rez.Drawables.V5Ember4SleepSmall,Rez.Drawables.V5Ember5SleepSmall,Rez.Drawables.V5Tide3SleepSmall,Rez.Drawables.V5Tide4SleepSmall,Rez.Drawables.V5Tide5SleepSmall,Rez.Drawables.V5Wisp3SleepSmall,Rez.Drawables.V5Wisp4SleepSmall,Rez.Drawables.V5Wisp5SleepSmall];
            }
            sprite=WatchUi.loadResource(ids[index]);cachedId=key;
        }
    }
    // Missing cache after an upgrade means OPEN GAME, never a full-save load
    // that can exhaust older devices before the foreground performs migration.
    function savedSummary(){return Storage.getValue("glance.v1") as Lang.Dictionary or Null;}
    function onUpdate(dc){
        readSummary();
        dc.setColor(0xFFFFFF,0x000000);dc.clear();
        if(sprite!=null){dc.drawBitmap(4,(dc.getHeight()-40)/2,sprite);}
        var name="EGG";var mood="OPEN GAME";var progress=0.0;
        if(snapshot!=null && snapshot.hasKey("cachedName")){
            name=snapshot["cachedName"];mood=BeastSleep.previewMood(snapshot,Time.now().value());progress=snapshot["cachedProgress"];
            if(snapshot["poop"]>0 && !BeastSleep.sleeping(snapshot,Time.now().value()) && BeastSleep.forecastEnergy(snapshot,Time.now().value())>=20){mood="CLEANUP";}
        }
        var font=Graphics.FONT_XTINY;var left=50;var width=dc.getWidth()-left-12;
        var lines=[name];var split=name.find(" ");
        if(dc.getTextWidthInPixels(name,font)>width && split!=null){
            lines=[name.substring(0,split),name.substring(split+1,name.length())];
        }
        var row=dc.getFontHeight(font);
        // Older Glance tiles are only 63px tall. Keep mood readable rather
        // than allowing a three-line name/status stack to cross the meter.
        if(row*(lines.size()+1)>dc.getHeight()-8){lines=[name];}
        for(var i=0;i<lines.size();i++){
            if(dc.getTextWidthInPixels(lines[i],font)>width){
                var shortened=lines[i];
                while(shortened.length()>0 && dc.getTextWidthInPixels(shortened+"..",font)>width){shortened=shortened.substring(0,shortened.length()-1);}
                lines[i]=shortened+"..";
            }
        }
        while(mood.length()>0 && dc.getTextWidthInPixels(mood,font)>width){mood=mood.substring(0,mood.length()-1);}
        var top=((dc.getHeight()-8-row*(lines.size()+1))/2).toNumber();
        if(top<0){top=0;}
        for(var j=0;j<lines.size();j++){drawLine(dc,left,top+row*j,font,lines[j]);}
        drawLine(dc,left,top+row*lines.size(),font,mood);
        if(snapshot!=null && BeastSleep.value(snapshot,"poop",0)>0){
            var pixels=[8,28,30,62,127,127];dc.setColor(0xFFFF55,Graphics.COLOR_TRANSPARENT);
            for(var r=0;r<pixels.size();r++){for(var c=0;c<7;c++){
                if((pixels[r]&(1<<(6-c)))!=0){dc.fillRectangle(dc.getWidth()-10+c,3+r,1,1);}
            }}
        }
        dc.setColor(0x005500,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(left,dc.getHeight()-8,width,4);
        dc.setColor(0x55AA55,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(left,dc.getHeight()-8,(width*progress).toNumber(),4);
    }
    function drawLine(dc,left,top,font,value){dc.drawText(left,top,font,value,Graphics.TEXT_JUSTIFY_LEFT);}
}
