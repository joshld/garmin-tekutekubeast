using Toybox.System;
using Toybox.Timer;
// One foreground-only, one-shot timer. No wall clock, polling, IO or redraws.
class BeastInactivity {
    var view=null;var timer=null;var last=null;var duration=0;var suspended=true;
    function initialize(){}
    static function choice(seconds){if(seconds==60){return 0;}if(seconds==300){return 1;}if(seconds==900){return 2;}if(seconds==3600){return 3;}return 4;}
    function clock(){return System.getTimer();}
    function cancel(){if(timer!=null){timer.stop();timer=null;}}
    function stop(){cancel();view=null;last=null;suspended=true;}
    function hide(target){if(view==target){cancel();view=null;}}
    function input(){last=clock();cancel();}
    function update(target){
        if(target.beast.data==null || target.beast.storagePaused || target.beast.pendingSession!=null){stop();return;}
        var seconds=target.beast.number("autoExit");
        var next=choice(seconds)==4?0:seconds*1000;
        var blocked=target.autoExitProtected();
        // Protection defers exit, never the input deadline. A changed setting
        // reschedules against that same baseline (real input already resets it).
        if(last==null){last=clock();}
        if(next!=duration){cancel();}
        view=target;duration=next;suspended=blocked;
        if(blocked || duration==0){cancel();return;}
        if(timer==null){arm(remaining());}
    }
    function remaining(){
        var now=clock();var elapsed=now-last;
        // System timer wrap/reset must never cause an immediate accidental exit.
        if(elapsed<0){last=now;elapsed=0;}return duration-elapsed;
    }
    function arm(delay){timer=new Timer.Timer();timer.start(method(:expired),delay>=50?delay:50,false);}
    function expired(){
        cancel();var target=view;if(target==null){return;}
        if(Toybox.Application.getApp().activeView!=target){stop();return;}
        update(target);if(suspended || duration==0){return;}
        var left=remaining();if(left>0){return;}
        stop();target.perform("timeout",null);
    }
}
