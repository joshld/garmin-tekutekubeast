using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Application;

// Short foreground-only games. BACK never consumes energy or a reward slot.
class BeastGameView extends TekuTekuBeastView {
    var kind;var phase=0;var elapsed=0;var attempts=0;var hits=0;var result="";
    var sequence=[];var cursor=0;var trail=0;var scanning=false;
    function initialize(model,game){
        TekuTekuBeastView.initialize();beast=model;kind=game;
        var settings=System.getDeviceSettings();
        if(settings has :inputButtons){scanning=(settings.inputButtons&System.BUTTON_INPUT_UP)==0;}
    }
    var touchWidth=280;
    function onShow(){
        if(refresher!=null){refresher.stop();refresher=null;}
        Application.getApp().activeView=self;
        if(!beast.dev){beast.data=null;}beast.syncHistory();
        refresher=new Toybox.Timer.Timer();refresher.start(method(:refresh),250,true);
    }
    function touch(point){
        if(kind==1 && phase==2){memoryInput(point[0]<touchWidth/3?0:(point[0]>touchWidth*2/3?2:1));WatchUi.requestUpdate();}
        else{selectAction();}
    }
    function refresh() as Void {
        if(phase==1){
            elapsed++;
            if(kind==0 && elapsed%16==0){catchStar(false);}
            if(kind==1 && elapsed>=sequence.size()*4){phase=2;cursor=0;}
        }
        tick++;WatchUi.requestUpdate();
    }
    function starPosition(){var t=elapsed%16;return t<=8?t/8.0:(16-t)/8.0;}
    function catchStar(check){
        var p=starPosition();if(check && p>=0.36 && p<=0.64){hits++;}
        attempts++;elapsed=((elapsed/16)+1)*16;
        if(attempts>=5){finish(hits>=3);}
    }
    function finish(win){
        if(phase==3){return;}phase=3;
        result=beast.gameReward(win,kind);new FeedbackManager().cue(beast,win?"happy":"miss");
    }
    function selectAction(){
        if(kind==2){
            result=beast.explore(trail);new FeedbackManager().cue(beast,"happy");WatchUi.requestUpdate();return;
        }
        if(phase==0){
            if(beast.number("energy")<10 && beast.number("games")<3){result="REST FIRST";WatchUi.requestUpdate();return;}
            phase=1;elapsed=0;
            if(kind==1){
                var seed=System.getTimer()%997;if(seed<0){seed=-seed;}seed=(seed+beast.number("games"))%997;
                var length=3+seed%3;
                for(var i=0;i<length;i++){seed=(seed*17+11)%997;sequence.add(seed%3);}
            }
        }else if(phase==1 && kind==0){catchStar(true);}
        else if(phase==2 && kind==1){memoryInput(scanning?(tick/4)%3:1);}
        else if(phase==3){WatchUi.popView(WatchUi.SLIDE_RIGHT);}
        WatchUi.requestUpdate();
    }
    function memoryInput(value){
        if(phase!=2){return;}
        if(sequence[cursor]!=value){finish(false);return;}
        cursor++;if(cursor>=sequence.size()){finish(true);}
    }
    function switchPage(delta){
        if(kind==2){trail=(trail+delta+4)%4;result="";}
        else if(kind==1){memoryInput(delta<0?0:2);}
        WatchUi.requestUpdate();
    }
    function back(){WatchUi.popView(WatchUi.SLIDE_RIGHT);return true;}
    function onUpdate(dc){
        touchWidth=dc.getWidth();
        dc.setColor(BG,BG);dc.clear();
        label(dc,y(dc,0.12),["STAR CATCH","MEMORY STEPS","TRAIL TREASURE"][kind],Graphics.FONT_SMALL);
        if(beast.dev){label(dc,y(dc,0.25),"DEV",Graphics.FONT_XTINY);}
        if(kind==2){
            label(dc,y(dc,0.34),"ENERGY "+beast.number("adventure"),Graphics.FONT_XTINY);
            label(dc,y(dc,0.48),["GROVE PATH","EMBER PATH","TIDE PATH","WISP PATH"][trail],Graphics.FONT_SMALL);
            label(dc,y(dc,0.64),result.length()>0?result:"SELECT TO EXPLORE",Graphics.FONT_XTINY);
            label(dc,y(dc,0.78),"PLAY OR MOVE",Graphics.FONT_XTINY);return;
        }
        if(phase==0){
            label(dc,y(dc,0.36),kind==0?"CATCH IN THE ZONE":"REMEMBER THE SYMBOLS",Graphics.FONT_XTINY);
            label(dc,y(dc,0.50),"SELECT TO START",Graphics.FONT_SMALL);
            label(dc,y(dc,0.68),result.length()>0?result:(beast.number("games")>=3?"FREE PRACTICE":"REWARDS "+beast.number("games")+"/3"),Graphics.FONT_XTINY);
        }else if(phase==3){
            label(dc,y(dc,0.39),result,Graphics.FONT_SMALL);
            label(dc,y(dc,0.55),kind==0?"CAUGHT "+hits+" / 5":"NICE MEMORY!",Graphics.FONT_XTINY);
            label(dc,y(dc,0.73),"SELECT TO RETURN",Graphics.FONT_XTINY);
        }else if(kind==0){
            var left=dc.getWidth()*0.2;var width=dc.getWidth()*0.6;var top=y(dc,0.49);
            dc.setColor(LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(left+width*0.36,top-13,width*0.28,30);
            dc.setColor(INK,Graphics.COLOR_TRANSPARENT);dc.drawLine(left,top,left+width,top);
            pixelIcon(dc,(left+width*starPosition()).toNumber()-7,top-7,[8,8,127,62,28,54,65],INK,2);
            label(dc,y(dc,0.66),"SELECT!  "+attempts+" / 5",Graphics.FONT_XTINY);
        }else{
            var show=phase==1?sequence[(elapsed/4).toNumber()]:-1;
            label(dc,y(dc,0.39),phase==1?"WATCH":"YOUR TURN",Graphics.FONT_XTINY);
            label(dc,y(dc,0.52),show<0?(cursor+1)+" / "+sequence.size():["UP","SELECT","DOWN"][show],Graphics.FONT_SMALL);
            label(dc,y(dc,0.72),scanning && phase==2?"SELECT: "+["UP","SELECT","DOWN"][(tick/4)%3]:"UP / SELECT / DOWN",Graphics.FONT_XTINY);
        }
    }
}
