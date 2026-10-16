using Toybox.Attention;
using Toybox.System;
using Toybox.Lang;

class FeedbackManager {
    static var lastCue=-2000;
    static var lastStatus="NOT TESTED";
    function initialize() {}
    function soundStatus(beast){
        var settings=System.getDeviceSettings();
        if(beast.isNight()){return "BEDTIME: QUIET";}
        if((settings has :doNotDisturb) && settings.doNotDisturb){return "WATCH DND";}
        if((settings has :tonesOn) && !settings.tonesOn){return "WATCH TONES OFF";}
        return (Attention has :playTone)?"SOUND READY":"NO TONE API";
    }
    function testCue(beast,tone){lastCue=-2000;play(beast,"evolve",tone);}
    function cue(beast,event){play(beast,event,null);}
    function play(beast,event,testSound){
        var t=System.getTimer();var delta=t.toLong()-lastCue.toLong();
        if(delta>=0 && delta<600){return;}lastCue=t;
        var settings=System.getDeviceSettings();
        if(beast.isNight() || ((settings has :doNotDisturb) && settings.doNotDisturb)){
            lastStatus=beast.isNight()?"BEDTIME: QUIET":"WATCH DND";return;
        }
        var toneAllowed=!(settings has :tonesOn) || settings.tonesOn;
        var vibrationAllowed=!(settings has :vibrateOn) || settings.vibrateOn;
        var sound=testSound==null?beast.number("sound")==1:testSound;
        var haptics=testSound==null?beast.number("haptics")==1:!testSound;
        lastStatus="FEEDBACK OFF";
        if(sound){
            lastStatus=toneAllowed?"NO TONE API":"WATCH TONES OFF";
            if(toneAllowed && (Attention has :playTone)){
                try{
                    if(Attention has :ToneProfile){
                        var pattern=event.equals("miss")?[[1800,130],[1400,110]]:
                            (event.equals("eat")?[[2400,100],[2800,120]]:
                            (event.equals("clean")?[[3200,90],[2400,110]]:
                            (event.equals("evolve")?[[2000,100],[2500,100],[3000,120],[4000,180]]:[[2600,110],[3400,140]])));
                        var notes=[];for(var i=0;i<pattern.size();i++){notes.add(new Attention.ToneProfile(pattern[i][0],pattern[i][1]));}
                        Attention.playTone({:toneProfile=>notes});
                    }else{Attention.playTone(Attention.TONE_KEY);}
                    lastStatus="TONE REQUESTED";
                }catch(e instanceof Lang.Exception){
                    System.println("Pet tone error: "+e.toString());lastStatus="TONE ERROR";
                    try{Attention.playTone(Attention.TONE_KEY);lastStatus="TONE FALLBACK";}
                    catch(f instanceof Lang.Exception){System.println("Pet fallback tone error: "+f.toString());}
                }
            }
        }
        if(haptics && !event.equals("miss")){
            if(!vibrationAllowed){if(!sound){lastStatus="WATCH VIBE OFF";}}
            else if(Attention has :vibrate){
                try{
                    var pulses=[new Attention.VibeProfile(35,140)];
                    if(beast.number("vibeStyle")==1 && (event.equals("happy") || event.equals("evolve"))){
                        pulses.add(new Attention.VibeProfile(0,100));pulses.add(new Attention.VibeProfile(40,event.equals("evolve")?200:140));
                    }
                    Attention.vibrate(pulses);if(!sound){lastStatus="VIBE REQUESTED";}
                }catch(e instanceof Lang.Exception){System.println("Pet vibration error: "+e.toString());lastStatus="VIBE ERROR";}
            }else if(!sound){lastStatus="NO VIBE API";}
        }
    }
}
