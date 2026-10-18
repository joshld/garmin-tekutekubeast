using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Timer;

// Rendering/input only. State owns durable turns, encounters and rewards;
// deterministic battle rules never depend on this view or its animation ticks.
class BeastBattleView extends TekuTekuBeastView {
    var battle=null;var battlePhase=0;var moveChoice=0;var battleNotice="";
    var burst=0;var battleTimer=null;var battlePictures=null;var battleForms=null;
    var battleWidth=280;var battleHeight=280;var battleSleeping=false;
    var battleResult="";var battleRedraws=0;var fight;
    var moveFont=null;var fontChecked=false;var compactGrid=false;
    var battleVisible=false;
    function initialize(model){TekuTekuBeastView.initialize();beast=model;fight=new BeastBattle(beast);}
    function onShow(){
        battleVisible=true;burst=0;
        Application.getApp().activeView=self;
        if(!beast.dev){beast.data=null;}beast.syncHistory();
        battle=fight.battleSession();battleSleeping=beast.isSleeping();
        battlePhase=battle==null?0:(battle["status"]==0?1:3);
        if(battlePhase==3){battleResult=fight.finishBattle();}
        loadBattleArt();tuneBattleTimer();
    }
    function onHide(){
        battleVisible=false;
        stopBattleTimer();fight.postponeBattle();
        battlePictures=null;battleForms=null;beast.commit();
    }
    function stopBattleTimer(){if(battleTimer!=null){battleTimer.stop();battleTimer=null;}}
    function tuneBattleTimer(){
        stopBattleTimer();if(!battleVisible){return;}battleTimer=new Timer.Timer();
        var period=burst>0?(beast.number("motion")==0?1000:(beast.number("motion")==1?500:250)):5000;
        battleTimer.start(method(:refresh),period,true);
    }
    function refresh() as Void {
        if(!battleVisible){return;}
        if(battle==null){burst=0;}
        var sleeping=beast.isSleeping();var changed=sleeping!=battleSleeping;
        battleSleeping=sleeping;
        if(sleeping && burst>0){burst=0;battlePhase=battle["status"]==0?1:3;changed=true;tuneBattleTimer();}
        if(burst>0){
            burst--;changed=true;
            if(burst==0){
                battlePhase=battle["status"]==0?1:3;
                if(battlePhase==3){battleResult=fight.finishBattle();}
                tuneBattleTimer();
            }
        }
        if(changed){battleRedraws++;WatchUi.requestUpdate();}
    }
    function asleepNotice(){
        if(!beast.isSleeping()){return false;}
        battleSleeping=true;battleNotice="Beast is asleep.";WatchUi.requestUpdate();return true;
    }
    function selectAction(){
        if(battlePhase==3){WatchUi.popView(WatchUi.SLIDE_RIGHT);return;}
        if(asleepNotice()){return;}battleNotice="";
        if(battlePhase==0){
            battle=fight.beginBattle();
            if(battle==null){battleNotice=beast.stage()==0?"Hatch before battling":"Find a wild encounter";}
            else{battlePhase=battle["status"]==0?1:3;loadBattleArt();}
        }else if(battlePhase==1){
            if(!BeastBattleRules.available(battle,moveChoice)){battleNotice="Technique recovering";WatchUi.requestUpdate();return;}
            battle=fight.battleTurn(moveChoice);
            if(battle==null){battlePhase=0;battleNotice="Battle paused";}
            else{
                battlePhase=2;burst=beast.number("motion")==0?2:(beast.number("motion")==1?4:8);
            }
        }
        tuneBattleTimer();WatchUi.requestUpdate();
    }
    function switchPage(delta){
        if(battlePhase==1 && !beast.isSleeping()){battleNotice="";moveChoice=(moveChoice+delta+4)%4;WatchUi.requestUpdate();}
    }
    function back(){fight.postponeBattle();WatchUi.popView(WatchUi.SLIDE_RIGHT);return true;}
    function touch(point){
        if(battlePhase==1 && point[1]>=battleHeight*0.60 && point[1]<battleHeight*0.86){
            moveChoice=(point[0]<battleWidth/2?0:1)+(point[1]>=battleHeight*0.73?2:0);
        }
        selectAction();
    }
    function loadBattleArt(){
        if(battle==null){return;}
        var p=battle["actors"][0];var e=battle["actors"][1];
        var key=p["form"]+":"+e["form"];
        if(battleForms!=null && battleForms.equals(key)){return;}
        battlePictures=null;var art=new BeastArt();
        // Keep only three compact poses per fighter, never pet/scenery sheets.
        var poses=art.frames(p["stage"],p["family"]);var left=[poses[0],poses[1],poses[4]];poses=null;
        poses=art.frames(e["stage"],e["family"]);battlePictures=[left,[poses[0],poses[1],poses[4]]];
        battleForms=key;
    }
    function battleText(dc,x,top,width,text){
        // Wrap at real font widths, including long signature names. Return the
        // complete lines for layout fixtures; never replace names with commands.
        var lines=[];var start=0;var gap=-1;var cursor=0;
        while(cursor<text.length()){
            if(text.substring(cursor,cursor+1).equals(" ")){gap=cursor;}
            if(dc.getTextWidthInPixels(text.substring(start,cursor+1),moveFont)>width && cursor>start){
                var end=gap>=start?gap:cursor;lines.add(text.substring(start,end));
                start=gap>=start?gap+1:cursor;cursor=start;gap=-1;
            }else{cursor++;}
        }
        if(start<text.length()){lines.add(text.substring(start,text.length()));}
        dc.setColor(INK,Graphics.COLOR_TRANSPARENT);
        for(var j=0;j<lines.size();j++){dc.drawText(x,top+j*dc.getFontHeight(moveFont),moveFont,lines[j],Graphics.TEXT_JUSTIFY_CENTER);}
        return lines;
    }
    function prepareMoveFont(){
        if(fontChecked){return;}fontChecked=true;
        if(Graphics has :getVectorFont){
            try{moveFont=Graphics.getVectorFont({:face=>"RobotoCondensedBold",:size=>16});}
            catch(e instanceof Toybox.Lang.Exception){}
        }
        compactGrid=moveFont!=null;if(moveFont==null){moveFont=Graphics.FONT_XTINY;}
    }
    function hpBar(dc,x,top,width,actor){
        dc.setColor(INK,Graphics.COLOR_TRANSPARENT);dc.drawRectangle(x,top,width,6);
        var fill=((width-2)*actor["hp"].toFloat()/actor["maxHp"]).toNumber();
        dc.fillRectangle(x+1,top+1,fill,4);
        dc.drawText(x+width/2,top+7,Graphics.FONT_XTINY,actor["hp"]+"/"+actor["maxHp"],Graphics.TEXT_JUSTIFY_CENTER);
    }
    function battleSpriteBox(dc,index,bitmap,bump){
        var ground=y(dc,0.58);var top=ground-bitmap.getHeight();
        var cx=dc.getWidth()*(index==0?0.30:0.70)+bump;
        var radius=dc.getWidth()/2-9;var cy=dc.getHeight()/2;
        var a=top-cy;if(a<0){a=-a;}var b=ground-cy;if(b<0){b=-b;}
        var dy=beast.max(a,b);var half=Toybox.Math.sqrt(beast.max(0,radius*radius-dy*dy))-bitmap.getWidth()/2;
        cx=beast.max(dc.getWidth()/2-half,beast.min(dc.getWidth()/2+half,cx));
        return [(cx-bitmap.getWidth()/2).toNumber(),top,bitmap.getWidth(),bitmap.getHeight()];
    }
    function battleSprite(dc,index){
        if(battlePictures==null){return;}
        var moving=beast.number("motion")>0 && battlePhase==2 && burst>0;
        var pose=moving?1:(battlePhase==3 && battle["status"]==1 && index==0?2:0);
        var bitmap=battlePictures[index][pose];
        var bump=moving && burst%2==0?(index==0?3:-3):0;
        var box=battleSpriteBox(dc,index,bitmap,bump);var cx=box[0]+box[2]/2;
        var ground=y(dc,0.58);dc.setColor(LIGHT,Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx-bitmap.getWidth()*0.35,ground,bitmap.getWidth()*0.70,2);
        dc.drawBitmap(box[0],box[1],bitmap);
        if(moving && ((burst%4>=2 && index==1)||(burst%4<2 && index==0))){
            pixelIcon(dc,cx+12,ground-bitmap.getHeight()/2,[8,42,28,127,28,42,8],INK,2);
        }
    }
    function onUpdate(dc){
        prepareMoveFont();
        battleWidth=dc.getWidth();battleHeight=dc.getHeight();sceneInk=INK;
        dc.setColor(BG,BG);dc.clear();label(dc,y(dc,0.08),"BATTLE",Graphics.FONT_XTINY);
        if(battle==null){
            label(dc,y(dc,0.28),fight.battleQueueCount()+" WAITING",Graphics.FONT_XTINY);
            label(dc,y(dc,0.40),"BATTLE XP "+fight.battleXp(),Graphics.FONT_XTINY);
            label(dc,y(dc,0.57),battleNotice.length()>0?battleNotice:"SELECT: MEET A BEAST",Graphics.FONT_XTINY);
            label(dc,y(dc,0.72),"UP/DOWN: CHOOSE",Graphics.FONT_XTINY);
            label(dc,y(dc,0.83),"BACK: LATER",Graphics.FONT_XTINY);return;
        }
        loadBattleArt();var actors=battle["actors"];
        hpBar(dc,dc.getWidth()*0.17,y(dc,0.18),dc.getWidth()*0.27,actors[0]);
        hpBar(dc,dc.getWidth()*0.56,y(dc,0.18),dc.getWidth()*0.27,actors[1]);
        battleSprite(dc,0);battleSprite(dc,1);
        if(battleSleeping || battleNotice.length()>0){
            label(dc,y(dc,0.62),battleSleeping?"Beast is asleep.":battleNotice,Graphics.FONT_XTINY);
            label(dc,y(dc,0.75),"BACK: PAUSE",Graphics.FONT_XTINY);return;
        }
        if(battlePhase==3){
            label(dc,y(dc,0.61),battle["status"]==1?"VICTORY!":(battle["status"]==2?"A BRAVE TRY!":"A CLOSE MATCH!"),Graphics.FONT_XTINY);
            label(dc,y(dc,0.72),battleResult,Graphics.FONT_XTINY);
            label(dc,y(dc,0.81),"SELECT: EXIT",Graphics.FONT_XTINY);return;
        }
        var names=BeastBattleMoves.names(actors[0]["form"]);
        if(battlePhase==2){
            var events=battle["events"];var half=beast.number("motion")==0?1:(beast.number("motion")==1?2:4);
            var event=events[events.size()>1 && burst<=half?1:0];
            battleText(dc,dc.getWidth()/2,y(dc,0.61),dc.getWidth()*0.76,(event["actor"]==0?"YOU: ":"WILD: ")+BeastBattleMoves.name(event["move"]));
            label(dc,y(dc,0.80),event["damage"]>0?"-"+event["damage"]+" HP":(event["effect"]==1?"PROTECTED":"POWER UP"),Graphics.FONT_XTINY);
            return;
        }
        var rowHeight=dc.getHeight()*0.13;
        if(!compactGrid){
            battleText(dc,dc.getWidth()/2,y(dc,0.61),dc.getWidth()*0.76,names[moveChoice]);
            label(dc,y(dc,0.80),(moveChoice+1)+" / 4",Graphics.FONT_XTINY);return;
        }
        for(var i=0;i<4;i++){
            var cellWidth=dc.getWidth()*(i<2?0.40:0.32);
            var x=dc.getWidth()*(i%2==0?(i<2?0.29:0.34):(i<2?0.71:0.66));var top=y(dc,i<2?0.59:0.72);
            if(i==moveChoice){dc.setColor(LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillRoundedRectangle(x-cellWidth/2,top-1,cellWidth,rowHeight,3);}
            battleText(dc,x,top,cellWidth-4,names[i]);
        }
    }
}
