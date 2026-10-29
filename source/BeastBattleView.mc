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
    var battleVisible=false;var replaying=false;
    var paused=false;var pauseOptions;var resumeTicks=0;var freshBattle=false;
    function initialize(model){TekuTekuBeastView.initialize();beast=model;fight=new BeastBattle(beast);pauseOptions=new BeastPauseOptions();}
    function onShow(){
        var retained=paused && battle!=null && fight.hasUnfinishedBattle() && battle["id"]==fight.data["active"]["id"];
        battleVisible=true;resumeTicks=0;pauseOptions.reset();
        Application.getApp().activeView=self;
        if(!beast.dev){beast.data=null;}beast.syncHistory();fight.discover();
        if(retained){loadBattleArt();WatchUi.requestUpdate();return;}
        fight.clearFinishedBattle();burst=0;battle=fight.battleSession();battleSleeping=beast.isSleeping();
        battlePhase=battle==null?0:(battle["status"]==0?1:3);
        replaying=false;
        // Replay the existing committed events after interruption, never execute
        // them again. The journal has actual (including lethal) damage, so HP
        // can be presented sequentially without copying or changing the save.
        if(battle!=null && battle["events"].size()>0 && !battle["claimed"]){
            replaying=true;beginPresentation();
        }else if(battlePhase==3){settleResult();}
        paused=!freshBattle && fight.hasUnfinishedBattle();freshBattle=false;
        loadBattleArt();tuneBattleTimer();
    }
    function onHide(){
        battleVisible=false;
        paused=fight.hasUnfinishedBattle();pauseOptions.reset();resumeTicks=0;
        stopBattleTimer();fight.postponeBattle();
        battlePictures=null;battleForms=null;beast.commit();
    }
    function stopBattleTimer(){if(battleTimer!=null){battleTimer.stop();battleTimer=null;}}
    function tuneBattleTimer(){
        if(!battleVisible || paused){stopBattleTimer();return;}
        if(battleTimer==null){battleTimer=new Timer.Timer();}else{battleTimer.stop();}
        // Four bounded callbacks for a two-action exchange. Timing is readable
        // even with Motion OFF; no continuous animation loop during a turn.
        var period=resumeTicks>0?1000:(burst>0?(burst%2==0?800:1200):5000);
        battleTimer.start(method(:refresh),period,resumeTicks==0 && burst==0);
    }
    function refresh() as Void {
        if(!battleVisible || paused){return;}
        if(resumeTicks>0){
            var left=pauseOptions.countdown(battleClock());
            if(left!=resumeTicks){resumeTicks=left;WatchUi.requestUpdate();}tuneBattleTimer();return;
        }
        if(battle==null){burst=0;}
        var sleeping=beast.isSleeping();var changed=sleeping!=battleSleeping;
        battleSleeping=sleeping;
        if(sleeping && burst>0){burst=0;battlePhase=battle["status"]==0?1:3;changed=true;tuneBattleTimer();}
        if(burst>0){
            burst--;changed=true;
            if(burst==0){
                battlePhase=battle["status"]==0?1:3;
                replaying=false;
                if(battlePhase==3){settleResult();}
            }
            tuneBattleTimer();
        }
        if(changed){battleRedraws++;WatchUi.requestUpdate();}
    }
    function battleClock(){return Toybox.System.getTimer();}
    function settleResult(){
        battleResult=fight.finishBattle();
        if(fight.data["active"]!=null){battle=fight.battleSession();}fight.clearFinishedBattle();
    }
    function asleepNotice(){
        if(!beast.isSleeping()){return false;}
        battleSleeping=true;battleNotice="Beast is asleep.";WatchUi.requestUpdate();return true;
    }
    function selectAction(){
        if(!battleVisible || resumeTicks>0){return;}
        if(paused){pauseSelect();return;}
        // Button repeats/taps must neither skip feedback nor restart its timer.
        if(battlePhase==2){return;}
        if(battlePhase==3){WatchUi.popView(WatchUi.SLIDE_RIGHT);return;}
        if(asleepNotice()){return;}battleNotice="";
        if(battlePhase==0){
            battle=fight.beginBattle();
            if(battle==null){battleNotice=beast.stage()==0?"Hatch before battling":"Find a wild encounter";}
            else{battlePhase=battle["status"]==0?1:3;loadBattleArt();}
        }else if(battlePhase==1){
            // Keep every named option visible while a signature recovers.
            // The selected-move hint explains the remaining own actions.
            if(!BeastBattleRules.available(battle,moveChoice)){WatchUi.requestUpdate();return;}
            battle=fight.battleTurn(moveChoice);
            if(battle==null){battlePhase=0;battleNotice="Battle paused";}
            else{
                replaying=false;beginPresentation();
            }
        }
        tuneBattleTimer();WatchUi.requestUpdate();
    }
    function switchPage(delta){
        if(!battleVisible || resumeTicks>0){return;}
        if(paused){pauseOptions.move(delta);WatchUi.requestUpdate();return;}
        if(battlePhase==1 && !beast.isSleeping()){battleNotice="";moveChoice=(moveChoice+delta+4)%4;WatchUi.requestUpdate();}
    }
    function pauseBattle(){
        paused=true;resumeTicks=0;pauseOptions.reset();stopBattleTimer();fight.postponeBattle();WatchUi.requestUpdate();
    }
    function resumeBattle(){paused=false;resumeTicks=3;pauseOptions.startReady(battleClock());tuneBattleTimer();WatchUi.requestUpdate();}
    function pauseSelect(){
        if(pauseOptions.confirming){
            if(pauseOptions.choice==0){pauseOptions.reset();WatchUi.requestUpdate();return;}
            if(pauseOptions.abandoning){
                if(!fight.abandonBattle(battle["id"])){return;}
                battle=null;onHide();returnToPet();return;
            }
            if(asleepNotice()){return;}
            var practice=battle["practice"];
            if(!practice && fight.battleQueueCount()==0){pauseOptions.reset();battleNotice="No encounters";WatchUi.requestUpdate();return;}
            if(!fight.abandonBattle(battle["id"])){return;}
            battle=practice?fight.practiceBattle():fight.beginBattle();
            battlePhase=battle==null?0:1;burst=0;replaying=false;moveChoice=0;battleNotice="";battleResult="";
            loadBattleArt();pauseOptions.reset();resumeBattle();return;
        }
        if(pauseOptions.choice==0){resumeBattle();return;}
        if(pauseOptions.choice==1){pauseOptions.confirm(false);WatchUi.requestUpdate();return;}
        if(pauseOptions.choice==3){pauseOptions.confirm(true);WatchUi.requestUpdate();return;}
        onHide();returnToPet();
    }
    function back(){
        if(!battleVisible){return true;}
        if(fight.hasUnfinishedBattle()){
            if(paused){pauseOptions.reset();WatchUi.requestUpdate();}else{pauseBattle();}return true;
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);return true;
    }
    function touch(point){
        if(!battleVisible || resumeTicks>0){return;}
        if(paused){selectAction();return;}
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
    function moveHint(){
        if(moveChoice==3){var cooldown=battle["actors"][0]["cooldown"];return cooldown>0?"Ready in "+cooldown+" moves":"Strong hit";}
        return ["Hit the wild beast","Soften next hit","Boost next 2 hits"][moveChoice];
    }
    function beginPresentation(){battlePhase=2;burst=battle["events"].size()*2;}
    function eventIndex(){return beast.max(0,(battle["events"].size()-(burst+1)/2).toNumber());}
    function resultVisible(){return burst%2==1;}
    function feedbackTarget(event){
        return event["damage"]<0 || event["effect"]==1 || event["effect"]==2?event["actor"]:1-event["actor"];
    }
    function feedbackText(event){
        if(event["damage"]>0){return "-"+event["damage"]+" HP";}
        if(event["damage"]<0){return "+"+(-event["damage"])+" HP";}
        return event["effect"]==1?"GUARD UP":(event["effect"]==2?"POWER UP":"MISS");
    }
    function displayHp(index){
        var actor=battle["actors"][index];var hp=actor["hp"];
        if(battlePhase!=2 || burst==0){return hp;}
        var events=battle["events"];var applied=eventIndex()+(resultVisible()?1:0);
        for(var i=applied;i<events.size();i++){
            var event=events[i];
            if(feedbackTarget(event)==index){hp+=event["damage"];}
        }
        return beast.max(0,beast.min(actor["maxHp"],hp));
    }
    function fighterLabel(dc,index){
        var cx=dc.getWidth()*(index==0?0.30:0.70);var top=y(dc,compactGrid?0.11:0.125);
        if(!compactGrid && battlePhase==2 && burst>0 && battle["events"][eventIndex()]["actor"]==index){
            dc.setColor(INK,Graphics.COLOR_TRANSPARENT);dc.drawLine(cx-16,top+dc.getFontHeight(moveFont),cx+16,top+dc.getFontHeight(moveFont));
        }
        battleText(dc,cx,top,dc.getWidth()*0.24,index==0?"YOU":"WILD");
    }
    function battleFeedback(dc){
        var events=battle["events"];var current=eventIndex();var youRows=0;var wildRows=0;
        var visible=current+(resultVisible()?1:0);
        for(var i=0;i<=current;i++){
            if(i==current && !resultVisible()){break;}
            var event=events[i];var target=feedbackTarget(event);var row=target==0?youRows:wildRows;
            if(!compactGrid){
                // Native-font displays have room for one result per fighter.
                // Each result is shown in its own timed phase; retain the latest.
                var later=false;for(var j=i+1;j<visible;j++){if(feedbackTarget(events[j])==target){later=true;}}
                if(later){continue;}
            }
            if(target==0){youRows++;}else{wildRows++;}
            battleText(dc,dc.getWidth()*(target==0?0.30:0.70),y(dc,compactGrid?0.59+row*0.06:0.64),dc.getWidth()*0.30,feedbackText(event));
        }
        var action=events[current];
        if(!compactGrid){
            battleText(dc,dc.getWidth()/2,y(dc,0.06),dc.getWidth()*0.32,replaying?"REPLAY":(resultVisible()?"RESULT":"MOVE"));
            battleText(dc,dc.getWidth()/2,y(dc,0.74),dc.getWidth()*0.46,BeastBattleMoves.name(action["move"]));return;
        }
        battleText(dc,dc.getWidth()/2,y(dc,0.71),dc.getWidth()*0.58,
            (action["actor"]==0?"YOU":"WILD")+(resultVisible()?" RESULT":" MOVE"));
        battleText(dc,dc.getWidth()/2,y(dc,0.78),dc.getWidth()*0.54,BeastBattleMoves.name(action["move"]));
    }
    function hpBar(dc,x,top,width,index){
        var actor=battle["actors"][index];var hp=displayHp(index);
        var barWidth=width;var labelX=x+width/2;var labelTop=top+7;
        if(!compactGrid){
            var textWidth=dc.getTextWidthInPixels(hp+"/"+actor["maxHp"],Graphics.FONT_XTINY);
            barWidth=width-textWidth-4;labelX=x+width-textWidth/2;labelTop=top;
            top+=7;
        }
        dc.setColor(INK,Graphics.COLOR_TRANSPARENT);dc.drawRectangle(x,top,barWidth,6);
        var fill=((barWidth-2)*hp.toFloat()/actor["maxHp"]).toNumber();
        dc.fillRectangle(x+1,top+1,fill,4);
        dc.drawText(labelX,labelTop,Graphics.FONT_XTINY,hp+"/"+actor["maxHp"],Graphics.TEXT_JUSTIFY_CENTER);
    }
    function battleSpriteBox(dc,index,bitmap,bump){
        var ground=y(dc,compactGrid?0.58:0.63);var top=ground-bitmap.getHeight();
        var cx=dc.getWidth()*(index==0?0.30:0.70)+bump;
        var radius=dc.getWidth()/2-9;var cy=dc.getHeight()/2;
        var a=top-cy;if(a<0){a=-a;}var b=ground-cy;if(b<0){b=-b;}
        var dy=beast.max(a,b);var half=Toybox.Math.sqrt(beast.max(0,radius*radius-dy*dy))-bitmap.getWidth()/2;
        cx=beast.max(dc.getWidth()/2-half,beast.min(dc.getWidth()/2+half,cx));
        return [(cx-bitmap.getWidth()/2).toNumber(),top,bitmap.getWidth(),bitmap.getHeight()];
    }
    function movingFighter(index){
        return beast.number("motion")>0 && battlePhase==2 && burst>0 && !resultVisible() && battle["events"][eventIndex()]["actor"]==index;
    }
    function battlePose(index){return movingFighter(index)?1:(battlePhase==3 && battle["status"]==1 && index==0?2:0);}
    function battleBump(index){return movingFighter(index)?(index==0?3:-3):0;}
    function battleSprite(dc,index){
        if(battlePictures==null){return;}
        var pose=battlePose(index);
        var bitmap=battlePictures[index][pose];
        var bump=battleBump(index);
        var box=battleSpriteBox(dc,index,bitmap,bump);var cx=box[0]+box[2]/2;
        var ground=y(dc,compactGrid?0.58:0.63);dc.setColor(LIGHT,Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx-bitmap.getWidth()*0.35,ground,bitmap.getWidth()*0.70,2);
        dc.drawBitmap(box[0],box[1],bitmap);
        if(beast.number("motion")>0 && battlePhase==2 && resultVisible() &&
                feedbackTarget(battle["events"][eventIndex()])==index && battle["events"][eventIndex()]["damage"]>0){
            pixelIcon(dc,cx+12,ground-bitmap.getHeight()/2,[8,42,28,127,28,42,8],INK,2);
        }
    }
    function onUpdate(dc){
        prepareMoveFont();
        battleWidth=dc.getWidth();battleHeight=dc.getHeight();sceneInk=INK;
        dc.setColor(BG,BG);dc.clear();
        if(paused){pauseOptions.draw(self,dc,"Restart Battle",pauseOptions.confirming?(battle["practice"]?"NO REWARDS":"USES NEXT ENCOUNTER"):(battleNotice.length()>0?battleNotice:"PROGRESS KEPT"));return;}
        if(resumeTicks>0){label(dc,y(dc,0.42),"READY "+resumeTicks,Graphics.FONT_XTINY);return;}
        if(battle==null){
            label(dc,y(dc,0.08),"BATTLE",Graphics.FONT_XTINY);
            label(dc,y(dc,0.28),fight.battleQueueCount()+" WAITING",Graphics.FONT_XTINY);
            label(dc,y(dc,0.40),"BATTLE XP "+fight.battleXp(),Graphics.FONT_XTINY);
            label(dc,y(dc,0.57),battleNotice.length()>0?battleNotice:"SELECT: MEET A BEAST",Graphics.FONT_XTINY);
            label(dc,y(dc,0.72),"UP/DOWN PICK MOVES",Graphics.FONT_XTINY);
            label(dc,y(dc,0.83),"BACK: LATER",Graphics.FONT_XTINY);return;
        }
        loadBattleArt();var actors=battle["actors"];
        if(compactGrid && replaying && battlePhase==2){battleText(dc,dc.getWidth()/2,y(dc,0.04),dc.getWidth()*0.26,"REPLAY");}
        fighterLabel(dc,0);fighterLabel(dc,1);
        hpBar(dc,dc.getWidth()*0.17,y(dc,compactGrid?0.18:0.215),dc.getWidth()*0.27,0);
        hpBar(dc,dc.getWidth()*0.56,y(dc,compactGrid?0.18:0.215),dc.getWidth()*0.27,1);
        battleSprite(dc,0);battleSprite(dc,1);
        if(battleSleeping || battleNotice.length()>0){
            label(dc,y(dc,compactGrid?0.62:0.65),battleSleeping?"Beast is asleep.":battleNotice,Graphics.FONT_XTINY);
            label(dc,y(dc,0.75),"BACK: PAUSE",Graphics.FONT_XTINY);return;
        }
        if(battlePhase==3){
            label(dc,y(dc,compactGrid?0.61:0.65),battle["status"]==1?"VICTORY!":(battle["status"]==2?"A BRAVE TRY!":"A CLOSE MATCH!"),Graphics.FONT_XTINY);
            label(dc,y(dc,compactGrid?0.72:0.75),battleResult,Graphics.FONT_XTINY);
            label(dc,y(dc,compactGrid?0.81:0.83),"SELECT: EXIT",Graphics.FONT_XTINY);return;
        }
        if(battlePhase==2){
            battleFeedback(dc);
            return;
        }
        var names=BeastBattleMoves.names(actors[0]["form"]);
        var rowHeight=dc.getHeight()*0.13;
        if(!compactGrid){
            battleText(dc,dc.getWidth()/2,y(dc,0.65),dc.getWidth()*0.60,names[moveChoice]);
            label(dc,y(dc,0.83),(moveChoice+1)+" / 4",Graphics.FONT_XTINY);return;
        }
        for(var i=0;i<4;i++){
            var cellWidth=dc.getWidth()*(i<2?0.40:0.32);
            var x=dc.getWidth()*(i%2==0?(i<2?0.29:0.34):(i<2?0.71:0.66));var top=y(dc,i<2?0.59:0.72);
            if(i==moveChoice){dc.setColor(LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillRoundedRectangle(x-cellWidth/2,top-1,cellWidth,rowHeight,3);}
            battleText(dc,x,top,cellWidth-4,names[i]);
        }
        battleText(dc,dc.getWidth()/2,y(dc,0.86),dc.getWidth()*0.46,moveHint());
    }
}
