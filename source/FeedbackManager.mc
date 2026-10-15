using Toybox.Attention;
using Toybox.System;
using Toybox.Lang;

class FeedbackManager {
    static var lastCue=-2000;
    function initialize() {}
    function cue(beast,event){
        var t=System.getTimer();var delta=t.toLong()-lastCue.toLong();if(delta>=0 && delta<750){return;}lastCue=t;
        var settings=System.getDeviceSettings();
        if(settings has :doNotDisturb && settings.doNotDisturb){return;}
        // Feature checks plus exception fallback: has() alone cannot guarantee
        // that a particular model's hardware supports every attention function.
        var toneAllowed=true;var vibrationAllowed=true;
        if(settings has :tonesOn){toneAllowed=settings.tonesOn;}
        if(settings has :vibrateOn){vibrationAllowed=settings.vibrateOn;}
        if(beast.number("sound")==1 && toneAllowed && (Attention has :playTone)){
            try {
                if(Attention has :ToneProfile){
                    var notes=[new Attention.ToneProfile(880,60)];
                    if(!event.equals("miss")){notes.add(new Attention.ToneProfile(1175,70));}
                    if(event.equals("evolve")){notes.add(new Attention.ToneProfile(1568,100));}
                    Attention.playTone({:toneProfile=>notes});
                }else{Attention.playTone(Attention.TONE_KEY);}
            }catch(e instanceof Lang.Exception){}
        }
        if(beast.number("haptics")==1 && vibrationAllowed && !event.equals("miss") && (Attention has :vibrate)){
            try{Attention.vibrate([new Attention.VibeProfile(25,60)]);}catch(e instanceof Lang.Exception){}
        }
    }
}
