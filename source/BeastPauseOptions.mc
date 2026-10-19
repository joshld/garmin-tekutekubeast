// Shared three-button pause choices; no timer, resources or saved game rules.
class BeastPauseOptions {
    var choice=0;var confirming=false;var abandoning=false;var readyAt=0;
    function initialize(){}
    function reset(){choice=0;confirming=false;abandoning=false;}
    function move(delta){choice=(choice+delta+(confirming?2:4))%(confirming?2:4);}
    function confirm(abandon){confirming=true;abandoning=abandon;choice=0;}
    function startReady(now){readyAt=now+3000;}
    function countdown(now){
        if(now<readyAt-3000){readyAt=now+3000;}
        return now>=readyAt?0:((readyAt-now+999)/1000).toNumber();
    }
    function draw(view,dc,restart,note){
        view.label(dc,view.y(dc,0.23),confirming?(abandoning?"ABANDON?":"RESTART?"):"PAUSED",Toybox.Graphics.FONT_XTINY);
        view.label(dc,view.y(dc,0.35),abandoning?"NO REWARD / REFUND":note,Toybox.Graphics.FONT_XTINY);
        view.label(dc,view.y(dc,0.47),(choice==0?"> ":"  ")+(confirming?"CANCEL":"Resume"),Toybox.Graphics.FONT_XTINY);
        view.label(dc,view.y(dc,0.58),(choice==1?"> ":"  ")+(confirming?"CONFIRM":restart),Toybox.Graphics.FONT_XTINY);
        if(!confirming){
            view.label(dc,view.y(dc,0.69),(choice==2?"> ":"  ")+"Exit",Toybox.Graphics.FONT_XTINY);
            view.label(dc,view.y(dc,0.80),(choice==3?"> ":"  ")+"Abandon",Toybox.Graphics.FONT_XTINY);
        }
    }
}
