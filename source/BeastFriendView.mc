using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Timer;
using Toybox.Application;
using Toybox.System;
using Toybox.Time;

// Reuses solo rendering/poses; protocol state is RAM-only and reward-free.
class BeastFriendView extends BeastBattleView {
    var radio=null;var link=null;var role=0;var digits;var digit=0;var entering=false;
    var pairCode=0;var visible=false;var seenChange=-1;var shownTurn=-1;var effectAt=0;
    var lastSleepCheck=0;var resultAt=0;var setupNotice="";var wasHidden=false;var leaveRequested=false;
    function initialize(model){TekuTekuBeastView.initialize();beast=model;digits=[1,0,0,0];radio=new BeastFriendAnt(method(:receiveFriend));}
    function fighterLabelPosition(index){return index==0?0.30:(compactGrid?0.67:0.64);}
    function nativePhaseHeader(){return false;}
    function opponentLabel(){return "FRIEND";}
    function moveHint(){return moveChoice==3?BeastBattleView.moveHint():["Hit your opponent","Soften next hit","Boost next 2 hits"][moveChoice];}
    function onShow(){
        visible=true;Application.getApp().activeView=self;
        if(wasHidden && link!=null && !link.phase.equals("CLOSED")){link.fail("INTERRUPTED - RECONNECT",battleClock());}
        wasHidden=false;tuneFriendTimer();WatchUi.requestUpdate();
    }
    function onHide(){
        visible=false;wasHidden=true;stopBattleTimer();radio.close();battlePictures=null;battleForms=null;
        if(link!=null && !link.phase.equals("CLOSED") && !link.phase.equals("RESULT")){link.fail("INTERRUPTED - RECONNECT",battleClock());}
    }
    function tuneFriendTimer(){
        stopBattleTimer();if(!visible || link==null || link.phase.equals("CLOSED")){return;}
        battleTimer=new Timer.Timer();battleTimer.start(method(:refresh),250,true);
    }
    function connectFriend(){
        if(!radio.supported()){setupNotice="ANT NOT SUPPORTED";return;}
        if(beast.isSleeping() || beast.stage()==0){setupNotice="BEAST MUST BE AWAKE";return;}
        try{
            var serial=BeastFriendModel.serial(beast);if(serial==0){setupNotice="SESSION LIMIT REACHED";return;}
            var epoch=Time.now().value()%65521;var now=battleClock();
            var nonce=((serial%65521)*719+epoch+now%65521)%65521;
            if(role==0){pairCode=1000+nonce%9000;}else{pairCode=digits[0]*1000+digits[1]*100+digits[2]*10+digits[3];}
            if(pairCode==0){setupNotice="ENTER HOST CODE";return;}
            link=new BeastFriendLink(role==0,serial,nonce,BeastFriendModel.snapshot(beast),now);
            if(link.phase.equals("CLOSED")){setupNotice=link.reason;return;}
            if(!radio.open(role==0,pairCode)){link.fail(radio.status,now);}
            seenChange=-1;shownTurn=-1;resultAt=0;lastSleepCheck=now;
            entering=false;syncFriend(now);pumpFriend(now);tuneFriendTimer();
        }catch(e instanceof Toybox.Lang.Exception){radio.close();setupNotice="CANNOT START ANT";System.println("FRIEND start: "+e.toString());link=null;}
    }
    function pumpFriend(now){var packet=link.next(now);if(packet!=null && radio.opened){radio.send(packet);}}
    function receiveFriend(packet){
        if(!visible || link==null){return;}var now=battleClock();link.receive(packet,now);pumpFriend(now);syncFriend(now);
    }
    function refresh() as Void {
        if(!visible || link==null){return;}var now=battleClock();
        if(!radio.opened && !link.phase.equals("CLOSED") && !link.phase.equals("RESULT")){link.fail(radio.status,now);}
        if(now-lastSleepCheck>=1000){lastSleepCheck=now;if(beast.isSleeping() && !link.phase.equals("RESULT") && !link.phase.equals("CLOSED") && !link.phase.equals("CLOSING")){link.cancel(now);link.reason="BEAST IS ASLEEP";}}
        pumpFriend(now);
        if(link.phase.equals("PRESENT") && now>=effectAt){
            if(burst>0){burst--;effectAt=now+(burst%2==0?800:1200);WatchUi.requestUpdate();}
            if(burst==0){link.presentationDone(now);}
        }
        if(link.phase.equals("RESULT")){
            if(resultAt==0){resultAt=now;}
            if(now-resultAt>=8000){radio.close();stopBattleTimer();if(leaveRequested){WatchUi.popView(WatchUi.SLIDE_RIGHT);return;}}
        }
        syncFriend(now);
    }
    function displayState(state){
        if(role==0){return state;}
        var copy=BeastBattleRules.copy(state);var a=copy["actors"][0];copy["actors"][0]=copy["actors"][1];copy["actors"][1]=a;
        for(var i=0;i<copy["events"].size();i++){copy["events"][i]["actor"]=1-copy["events"][i]["actor"];}
        if(copy["status"]==1){copy["status"]=2;}else if(copy["status"]==2){copy["status"]=1;}return copy;
    }
    function syncFriend(now){
        if(link==null || seenChange==link.changed){return;}seenChange=link.changed;
        if(link.phase.equals("CLOSED")){radio.close();stopBattleTimer();battlePictures=null;battleForms=null;}
        if(link.remoteActor!=null && battle==null){battle=displayState(link.startState());loadBattleArt();}
        if(link.battle!=null && link.battle["turn"]!=shownTurn){
            shownTurn=link.battle["turn"];battle=displayState(link.battle);moveChoice=0;
            if(shownTurn>0 && link.phase.equals("PRESENT")){beginPresentation();effectAt=now+800;}
        }
        if(link.phase.equals("PLAY")){battlePhase=1;burst=0;}
        if(link.phase.equals("RESULT")){battlePhase=3;battleResult="FRIEND MATCH - NO XP";}
        WatchUi.requestUpdate();
    }
    function leaveFriend(){
        // Keep acknowledging a confirmed final turn through the bounded retry
        // window. Leaving early must not strand the other watch at SYNCING.
        if(link.phase.equals("RESULT") && radio.opened){leaveRequested=true;battleResult="FINISHING / NO XP";WatchUi.requestUpdate();return;}
        radio.close();WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
    function selectAction(){
        if(!visible){return;}
        if(link==null){
            if(role==1 && !entering){entering=true;digit=0;}
            else if(entering && digit<3){digit++;}
            else{connectFriend();}
            WatchUi.requestUpdate();return;
        }
        var now=battleClock();
        if(link.phase.equals("CLOSED") || link.phase.equals("RESULT")){leaveFriend();return;}
        if(link.phase.equals("READY")){link.ready(now);}
        else if(link.phase.equals("PLAY")){link.choose(moveChoice,now);}
        pumpFriend(now);syncFriend(now);
    }
    function switchPage(delta){
        if(link==null){if(entering){digits[digit]=(digits[digit]+delta+10)%10;}else{role=(role+1)%2;}WatchUi.requestUpdate();return;}
        if(link.phase.equals("PLAY") && link.choice<0){moveChoice=(moveChoice+delta+4)%4;WatchUi.requestUpdate();}
    }
    function back(){
        if(link==null){if(entering){entering=false;WatchUi.requestUpdate();return true;}WatchUi.popView(WatchUi.SLIDE_RIGHT);return true;}
        if(link.phase.equals("CLOSED") || link.phase.equals("RESULT")){leaveFriend();return true;}
        link.cancel(battleClock());pumpFriend(battleClock());syncFriend(battleClock());return true;
    }
    function touch(coords){if(link==null || link.phase.equals("READY")){selectAction();return;}if(link.phase.equals("PLAY") && link.choice<0){if(coords[1]>=battleHeight*0.60 && coords[1]<battleHeight*0.86){moveChoice=(coords[0]<battleWidth/2?0:1)+(coords[1]>=battleHeight*0.73?2:0);}selectAction();}}
    function battlePrompt(dc){
        var note="WAITING FOR FRIEND";
        if(link.phase.equals("READY")){note=link.localReady?"WAITING FOR READY":"SELECT: READY";}
        else if(link.phase.equals("TURN") || link.phase.equals("COMMIT")){note="SYNCING TURN";}
        else if(link.phase.equals("PRESENT")){note="CONFIRMING RESULT";}
        var top=y(dc,compactGrid?0.63:0.66);
        battleText(dc,dc.getWidth()/2,top,dc.getWidth()*0.70,note);
        if(link.phase.equals("READY")){
            battleText(dc,dc.getWidth()/2,y(dc,0.74),dc.getWidth()*0.62,BeastBattleMoves.species(link.remoteActor["form"]));
        }else if(link.choice>=0){
            battleText(dc,dc.getWidth()/2,y(dc,0.74),dc.getWidth()*0.60,BeastBattleMoves.name(BeastBattleMoves.id(battle["actors"][0]["form"],link.choice)));
        }
        if(compactGrid){battleText(dc,dc.getWidth()/2,y(dc,0.88),dc.getWidth()*0.42,"BACK: CANCEL");}
    }
    function onUpdate(dc){
        prepareMoveFont();battleWidth=dc.getWidth();battleHeight=dc.getHeight();sceneInk=INK;
        if(link==null){
            dc.setColor(BG,BG);dc.clear();label(dc,y(dc,0.16),"BATTLE A FRIEND",Graphics.FONT_XTINY);
            if(entering){
                label(dc,y(dc,0.30),"ENTER HOST CODE",Graphics.FONT_XTINY);
                for(var i=0;i<4;i++){
                    var cx=dc.getWidth()*(0.32+i*0.12);dc.setColor(i==digit?INK:LIGHT,Graphics.COLOR_TRANSPARENT);
                    dc.drawText(cx,y(dc,0.43),Graphics.FONT_SMALL,digits[i].toString(),Graphics.TEXT_JUSTIFY_CENTER);
                    if(i==digit){dc.drawLine(cx-7,y(dc,0.58),cx+7,y(dc,0.58));}
                }
                label(dc,y(dc,0.68),"UP/DOWN: DIGIT",Graphics.FONT_XTINY);label(dc,y(dc,0.78),digit==3?"SELECT: JOIN":"SELECT: NEXT",Graphics.FONT_XTINY);
            }else{
                label(dc,y(dc,0.34),(role==0?"> ":"")+"Host",Graphics.FONT_XTINY);label(dc,y(dc,0.48),(role==1?"> ":"")+"Join",Graphics.FONT_XTINY);
                label(dc,y(dc,0.65),setupNotice.length()>0?setupNotice:"NEARBY WATCHES / NO XP",Graphics.FONT_XTINY);
                label(dc,y(dc,0.78),"UP/DOWN / SELECT",Graphics.FONT_XTINY);
            }return;
        }
        if(battle==null || link.phase.equals("CLOSED") || link.phase.equals("CLOSING")){
            dc.setColor(BG,BG);dc.clear();label(dc,y(dc,0.16),"FRIEND BATTLE",Graphics.FONT_XTINY);
            if(link.phase.equals("SEARCH") || link.phase.equals("HELLO")){
                label(dc,y(dc,0.31),role==0?"SHARE THIS CODE":"CONNECTING",Graphics.FONT_XTINY);
                label(dc,y(dc,0.43),pairCode.toString(),Graphics.FONT_MEDIUM);
                label(dc,y(dc,0.64),"BOTH WATCHES STAY OPEN",Graphics.FONT_XTINY);
                label(dc,y(dc,0.78),"BACK: CANCEL",Graphics.FONT_XTINY);
            }else{
                battleText(dc,dc.getWidth()/2,y(dc,0.37),dc.getWidth()*0.70,link.phase.equals("CLOSED") || link.phase.equals("CLOSING")?link.reason:"EXCHANGING BEASTS");
                label(dc,y(dc,0.72),link.phase.equals("CLOSED")?"SELECT: EXIT":"BACK: CANCEL",Graphics.FONT_XTINY);
            }return;
        }
        battleNotice=(link.phase.equals("READY") || (link.phase.equals("PLAY") && link.choice>=0) || link.phase.equals("TURN") || link.phase.equals("COMMIT") || (link.phase.equals("PRESENT") && burst==0))?"FRIEND":"";
        BeastBattleView.onUpdate(dc);
    }
}
