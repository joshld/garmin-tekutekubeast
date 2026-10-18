using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Math;
using Toybox.System;

// Original precompiled landscape layers. Only the currently visible theme/time
// is loaded. No runtime foliage construction, full-screen buffers or timers.
class BeastScenery {
    var layer=null;var layerKey=-1;var buildMs=0;var cachedDrawMs=0;var ink=0x005500;var audit=false;
    var fraction=-1.0;var celestialX=0;var celestialY=0;
    var ids=[
        [Rez.Drawables.ForestDawn,Rez.Drawables.ForestDay,Rez.Drawables.ForestDusk,Rez.Drawables.ForestNight],
        [Rez.Drawables.MeadowDawn,Rez.Drawables.MeadowDay,Rez.Drawables.MeadowDusk,Rez.Drawables.MeadowNight],
        [Rez.Drawables.LakesideDawn,Rez.Drawables.LakesideDay,Rez.Drawables.LakesideDusk,Rez.Drawables.LakesideNight],
        [Rez.Drawables.GardenDawn,Rez.Drawables.GardenDay,Rez.Drawables.GardenDusk,Rez.Drawables.GardenNight]];
    var skyColors=[0xFFAAAA,0xAAFFFF,0xAA55AA,0x000055];
    var horizonColors=[0xFFFFAA,0xAAFFFF,0xFFAAAA,0x5555AA];
    function initialize(){}
    function release(){layer=null;layerKey=-1;}
    function pixel(dc,x,y,w,h,color){var u=dc.getWidth()/140.0;dc.setColor(color,Graphics.COLOR_TRANSPARENT);dc.fillRectangle((x*u).toNumber(),(y*u).toNumber(),Math.ceil(w*u).toNumber(),Math.ceil(h*u).toNumber());}
    function clearing(dc,x,top,size,phase,lightsOff){
        // Three static pixel-stepped pools, behind the unchanged native sprite.
        // No alpha buffers, new assets, resource loads, timers or sky modification.
        if(lightsOff || phase==1){return;}
        var cx=x+size/2;var foot=top+size;var unit=(dc.getWidth()/140).toNumber();if(unit<1){unit=1;}
        dc.setColor(0x005555,Graphics.COLOR_TRANSPARENT);dc.fillEllipse(cx-size*0.48,foot-size*0.24,size*0.96,size*0.30);
        dc.setColor(0x555555,Graphics.COLOR_TRANSPARENT);dc.fillEllipse(cx-size*0.38,foot-size*0.18,size*0.76,size*0.22);
        dc.setColor(0xAAAA55,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(cx-size*0.27,foot-size*0.10,size*0.54,3*unit);
    }
    function draw(dc,theme,sky,lightsOff){
        var started=audit?System.getTimer():0;var phase=sky[0];var terrain=lightsOff?3:phase;
        var key=theme*4+terrain;
        if(key!=layerKey || layer==null){release();layer=WatchUi.loadResource(ids[theme][terrain]);layerKey=key;if(audit){buildMs=System.getTimer()-started;}}
        var renderStart=audit?System.getTimer():0;
        var skyColor=skyColors[phase];ink=phase==3 || lightsOff?0xAAFFAA:0x005500;
        dc.setColor(skyColor,skyColor);dc.clear();pixel(dc,0,37,140,24,horizonColors[phase]);
        if(fraction!=sky[1]){fraction=sky[1];celestialX=25+90*fraction;celestialY=54-22*Math.sin(fraction*Math.PI);}
        if(sky[2]){
            pixel(dc,celestialX-2,celestialY-4,4,8,0xFFFFAA);pixel(dc,celestialX-4,celestialY-2,8,4,0xFFFFAA);
            pixel(dc,celestialX-1,celestialY-2,2,4,0xFFFF55);
        }else if(phase==3){
            for(var star=0;star<8;star++){pixel(dc,26+(star*29)%90,18+(star*11)%28,1,1,0xAAAAAA);}
            // Decorative night-progress crescent, not true lunar rise/set/phase.
            pixel(dc,celestialX-2,celestialY-4,4,8,0xFFFFAA);pixel(dc,celestialX-4,celestialY-2,8,4,0xFFFFAA);
            pixel(dc,celestialX,celestialY-4,3,6,skyColor);pixel(dc,celestialX+2,celestialY-2,3,4,skyColor);
        }
        dc.drawBitmap(0,0,layer);if(audit){cachedDrawMs=System.getTimer()-renderStart;}
    }
}
