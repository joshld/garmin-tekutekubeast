// Shared three-button pause choices; no timer, resources or saved game rules.
class BeastPauseOptions {
    var choice=0;var confirming=false;
    function initialize(){}
    function reset(){choice=0;confirming=false;}
    function move(delta){choice=(choice+delta+(confirming?2:3))%(confirming?2:3);}
    function confirm(){confirming=true;choice=0;}
    function draw(view,dc,restart,note){
        view.label(dc,view.y(dc,0.24),confirming?"RESTART?":"PAUSED",Toybox.Graphics.FONT_XTINY);
        view.label(dc,view.y(dc,0.38),note,Toybox.Graphics.FONT_XTINY);
        view.label(dc,view.y(dc,0.51),(choice==0?"> ":"  ")+(confirming?"CANCEL":"Resume"),Toybox.Graphics.FONT_XTINY);
        view.label(dc,view.y(dc,0.64),(choice==1?"> ":"  ")+(confirming?"CONFIRM":restart),Toybox.Graphics.FONT_XTINY);
        if(!confirming){view.label(dc,view.y(dc,0.77),(choice==2?"> ":"  ")+"Exit",Toybox.Graphics.FONT_XTINY);}
    }
}
