using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Application;

// Durable whole sessions. Rounds never award independently. BACK pauses;
// killing/reopening resumes checkpoints without another expedition charge.
class BeastGameView extends TekuTekuBeastView {
    var kind;var phase=0;var elapsed=0;var attempts=0;var hits=0;var result="";
    var sequence=[];var cursor=0;var trail=0;var scanning=false;var touchWidth=280;
    var session=null;var round=0;var score=0;var combo=0;var best=0;var retries=0;
    var lane=1;var target=1;var jumpTicks=0;var caught=false;var resultChoice=0;
    var node=0;var choice=0;var travel=0;var hint="";var replayRound=false;var gameBounds=[0,0,0,0];
    var lastGameVisual=null;var gameRedraws=0;
    function initialize(model,game){
        TekuTekuBeastView.initialize();beast=model;kind=game;
        var settings=System.getDeviceSettings();
        if(settings has :inputButtons){scanning=(settings.inputButtons&System.BUTTON_INPUT_UP)==0;}
    }
    function loadSprite(){
        var s=beast.stage();var f=beast.family();if(s==spriteStage && f==spriteFamily){return;}
        frames=null;sprite=null;spriteStage=s;spriteFamily=f;
        frames=new BeastArt().frames(s,f);sprite=frames[0];
    }
    function onShow(){
        if(refresher!=null){refresher.stop();refresher=null;}
        Application.getApp().activeView=self;if(!beast.dev){beast.data=null;}beast.syncHistory();loadSprite();
        var saved=beast.data["sessions"][kind];
        if(saved!=null){restore(saved);}
        refresher=new Toybox.Timer.Timer();timerPeriod=desiredGamePeriod();refresher.start(method(:refresh),timerPeriod,true);
    }
    function desiredGamePeriod(){
        if(phase==0 || phase==3){return beast.number("motion")==0 && kind!=2?5000:1000;}
        if(phase==2 && kind==2){return 5000;}
        if(phase==2 && kind==1 && !scanning){return 1000;}return 250;
    }
    function tuneGameTimer(){
        var wanted=desiredGamePeriod();
        if(refresher!=null && timerPeriod!=wanted){timerPeriod=wanted;refresher.stop();refresher.start(method(:refresh),timerPeriod,true);}
    }
    function onHide(){checkpoint();TekuTekuBeastView.onHide();}
    function restore(saved){
        session=beast.store.copy(saved);phase=session["phase"];elapsed=session["elapsed"];
        attempts=session["attempts"];hits=session["hits"];score=session["score"];combo=session["combo"];
        best=session["best"];round=session["round"];cursor=session["cursor"];sequence=beast.store.copy(session["sequence"]);
        retries=session["retries"];trail=session["route"];node=session["node"];choice=session["choice"];travel=session["travel"];
        lane=session.hasKey("lane")?session["lane"]:1;target=session.hasKey("target")?session["target"]:1;
        jumpTicks=session.hasKey("jump")?session["jump"]:0;caught=session.hasKey("caught")?session["caught"]:false;
        replayRound=session.hasKey("retry")?session["retry"]:false;
        hint=session.hasKey("hint")?session["hint"]:"";
        // Preserve the position within an older saved cue/star; never restart
        // its round, random seed, attempts, rewards or adventure transaction.
        if(!session.hasKey("timingV051")){
            if(kind==1 && phase==1){elapsed=(elapsed/tempo()).toNumber()*(tempo()+cueGap())+elapsed%tempo();}
            if(kind==0 && phase==1 && beast.number("easy")==0){elapsed=(elapsed*period()/[20.0,16.0,12.0][round]).toNumber();jumpTicks=beast.min(jumpTicks,jumpDuration());}
            session["timingV051"]=1;
        }
        // Power loss may occur between the model's atomic session/debit and
        // the first view checkpoint. Complete setup using the SAME ID/seed;
        // never restart the transaction or charge/grant anything again.
        var incomplete=false;
        if(kind==1 && phase==1 && sequence.size()==0){makeSequence();incomplete=true;}
        if(kind==2 && phase==1){phase=5;incomplete=true;}
        if(kind==0 && phase==1 && !session.hasKey("target")){target=random(3);incomplete=true;}
        if(incomplete){checkpoint();}
    }
    function checkpoint(){
        if(session==null || phase==3){return;}
        session["phase"]=phase;session["elapsed"]=elapsed;session["attempts"]=attempts;session["hits"]=hits;
        session["score"]=score;session["combo"]=combo;session["best"]=best;session["round"]=round;
        session["cursor"]=cursor;session["sequence"]=beast.store.copy(sequence);session["retries"]=retries;
        session["route"]=trail;session["node"]=node;session["choice"]=choice;session["travel"]=travel;
        session["lane"]=lane;session["target"]=target;session["jump"]=jumpTicks;session["caught"]=caught;session["retry"]=replayRound;
        session["hint"]=hint;
        session["timingV051"]=1;
        beast.saveSession(session);
    }
    function random(limit){session["seed"]=BeastGameRules.nextSeed(session["seed"]);return session["seed"]%limit;}
    function begin(){
        session=beast.beginSession(kind);if(session==null){result="CARE / PLAY EARNS IT";return;}
        // A paused session is resumed, not replaced or charged twice.
        if(session["elapsed"]>0 || session["node"]>0 || session["sequence"].size()>0 || session["travel"]>0){restore(session);return;}
        phase=kind==2?5:1;round=0;elapsed=0;attempts=0;hits=0;score=0;combo=0;best=0;retries=0;node=0;
        result="";choice=0;resultChoice=0;travel=0;lane=1;jumpTicks=0;caught=false;
        if(kind==0){target=random(3);}
        if(kind==1){makeSequence();}
        checkpoint();tuneGameTimer();
    }
    function makeSequence(){
        sequence=[];for(var i=0;i<3+round;i++){sequence.add(random(3));}
        cursor=0;elapsed=0;phase=1;
    }
    function refresh() as Void {
        var step=timerPeriod/250;tick+=step;if(phase==1 || phase==2 || phase==4 || phase==5){elapsed+=step;}
        if(kind==0 && phase==1){
            if(jumpTicks>0){jumpTicks--;}
            var local=elapsed.toFloat()/period();
            if(!caught && jumpTicks>0 && lane==target && local>=0.40 && local<=(beast.number("easy")==1?0.96:0.94)){
                caught=true;hits++;combo++;best=beast.max(best,combo);score+=10+beast.min(5,combo)*2;
                hint=combo>1?"COMBO "+combo:"GOT IT!";new FeedbackManager().cue(beast,"happy");checkpoint();
            }
            if(elapsed>=period()){catchStar(false);}
        }
        if(kind==1 && phase==1 && elapsed>=sequence.size()*(tempo()+cueGap())){phase=2;elapsed=0;cursor=0;checkpoint();}
        if(kind==1 && phase==2 && elapsed>=120){memoryInput(-1);}
        if(kind==1 && phase==4 && elapsed>=12){continueMemory();}
        if(kind==2 && phase==5){travel++;if(travel>=12){phase=2;elapsed=0;travel=0;choice=0;checkpoint();}}
        if(kind==2 && phase==4 && elapsed>=10){nextTrail();}
        tuneGameTimer();var key=gameVisualKey();
        if(lastGameVisual==null || !lastGameVisual.equals(key)){lastGameVisual=key;gameRedraws++;WatchUi.requestUpdate();}
    }
    function gameVisualKey(){
        var motion=beast.number("motion");var artTick=0;
        if(kind==0 && phase==1 || kind==2 && phase==5){artTick=tick;}
        else if(kind==1 && phase==1){artTick=displayedMove()+10*(elapsed/(tempo()+cueGap())).toNumber();}
        else if(kind==1 && phase==2 && scanning){artTick=(tick/6)%3;}
        else if((phase==0 || phase==3) && motion>0){artTick=tick%24;}
        else if(phase==0 && kind==2){artTick=(tick/8)%2;}
        return phase+":"+artTick+":"+cursor+":"+round+":"+retries+":"+choice+":"+resultChoice+":"+hint+":"+score+":"+lane;
    }
    function period(){return BeastGameRules.period(beast.number("easy")==1,round);}
    function tempo(){return BeastGameRules.tempo(beast.number("easy")==1);}
    function cueGap(){return BeastGameRules.cueGap();} // includes UP -> UP
    function displayedMove(){
        return BeastGameRules.displayedMove(sequence,phase,elapsed,beast.number("easy")==1);
    }
    function jumpDuration(){return BeastGameRules.jumpDuration(beast.number("easy")==1,round);}
    function starPosition(){return elapsed.toFloat()/period();}
    function catchStar(check){
        // The pet must actually jump into a falling star; input never awards it
        // merely by hitting an invisible timing bar.
        if(check){if(jumpTicks==0){jumpTicks=jumpDuration();}return;}
        attempts++;if(!caught){combo=0;hint="NEXT STAR!";}
        if(attempts>=15){finish(hits>=7);return;}
        round=attempts/5;target=random(3);caught=false;jumpTicks=0;elapsed=0;checkpoint();
    }
    function finish(win){
        if(phase==3 || session==null){return;}
        checkpoint();result=beast.completeSession(session,win);session=null;phase=3;resultChoice=0;
        new FeedbackManager().cue(beast,win?"happy":"miss");
    }
    function continueMemory(){
        if(replayRound){replayRound=false;elapsed=0;phase=1;cursor=0;}
        else{round++;if(round>=3){finish(hits>=2);return;}retries=0;makeSequence();}
        checkpoint();
    }
    function memoryInput(value){
        if(phase!=2 || kind!=1){return;}
        if(sequence[cursor]!=value){
            retries++;cursor=0;phase=4;elapsed=0;replayRound=retries<2;
            hint=replayRound?"TRY AGAIN":"NEXT ROUND";
            new FeedbackManager().cue(beast,"miss");checkpoint();return;
        }
        cursor++;elapsed=0;
        if(cursor>=sequence.size()){
            hits++;score+=sequence.size()*(retries==0?20:10);hint="GREAT!";
            phase=4;elapsed=0;replayRound=false;new FeedbackManager().cue(beast,"happy");
        }
        checkpoint();
    }
    function chooseTrail(){
        if(session==null || phase!=2){return;}
        // Safe helping/searching and bold routes affect discoveries/chances.
        var bonus=choice==0?1:random(3);
        session["finds"]+=bonus;session["risk"]+=choice;
        session["seed"]=BeastGameRules.trailSeed(session["seed"],trail,node,choice);
        hint=choice==0?["A FRIEND HELPS","A HIDDEN CLUE","A CHEST AHEAD"][node]:
            (bonus>0?["A SECRET PATH!","GLOWING TRACKS!","A RARE GLIMMER!"][node]:"A QUIET DETOUR");
        phase=4;elapsed=0;checkpoint();
    }
    function nextTrail(){
        node++;if(node>=3){finish(true);return;}phase=5;travel=0;elapsed=0;checkpoint();
    }
    function selectAction(){
        if(phase==0){begin();}
        else if(phase==3){
            if(resultChoice==1){WatchUi.popView(WatchUi.SLIDE_RIGHT);return;}phase=0;begin();
        }else if(kind==0 && phase==1){catchStar(true);}
        else if(kind==1 && phase==2){memoryInput(scanning?(tick/6)%3:1);}
        else if(kind==1 && phase==4){continueMemory();}
        else if(kind==2 && phase==2){chooseTrail();}
        else if(kind==2 && phase==4){nextTrail();}
        tuneGameTimer();WatchUi.requestUpdate();
    }
    function switchPage(delta){
        if(phase==0){
            if(kind==2){trail=(trail+delta+4)%4;}
            else{beast.data["easy"]=1-beast.number("easy");beast.commit();}
        }else if(phase==3){resultChoice=1-resultChoice;}
        else if(kind==0 && phase==1){lane=(lane+(delta<0?-1:1)+3)%3;}
        else if(kind==1 && phase==2){memoryInput(delta<0?0:2);}
        else if(kind==2 && phase==2){choice=1-choice;}
        WatchUi.requestUpdate();
    }
    function touch(point){
        if(phase==3){resultChoice=resultTouchChoice(point[1]);selectAction();return;}
        if(kind==0 && phase==1){lane=point[0]<touchWidth/3?0:(point[0]>touchWidth*2/3?2:1);selectAction();}
        else if(kind==1 && phase==2){memoryInput(point[0]<touchWidth/3?0:(point[0]>touchWidth*2/3?2:1));WatchUi.requestUpdate();}
        else{selectAction();}
    }
    function resultTouchChoice(top){return top>touchWidth*0.845?1:0;}
    function resultDetail(){
        if(kind!=2){return "SCORE "+score+"  BEST "+(kind==0?best:hits);}
        return result.equals("SCOUT COMPLETE")?"SCOUT: NO LOOT":"IN YOUR COLLECTION";
    }
    function trailChoice(){
        if(node==2){return choice==0?"> OPEN SLOWLY":"> PUSH OPEN";}
        var safe=node==0?["HELP","SEARCH","FOLLOW","FOLLOW"]:["CROSS","CLIMB","SEARCH","READ"];
        var bold=node==0?["EXPLORE","CLIMB","DIVE","CHASE"]:["DETOUR","CIRCLE","DIVE","TOUCH"];
        return "> "+(choice==0?safe[trail]:bold[trail]);
    }
    function back(){checkpoint();WatchUi.popView(WatchUi.SLIDE_RIGHT);return true;}
    function drawPlayer(dc,cx,ground,pose,hop){
        if(frames==null){loadSprite();}
        var bitmap=frames[pose];var size=bitmap.getWidth();
        var top=beast.max(y(dc,0.32),(ground-size-hop).toNumber());
        var radius=dc.getWidth()/2-9;var a=top-dc.getHeight()/2;if(a<0){a=-a;}
        var b=top+size-dc.getHeight()/2;if(b<0){b=-b;}var dy=beast.max(a,b);
        var half=Toybox.Math.sqrt(beast.max(0,radius*radius-dy*dy))-size/2;
        cx=beast.max(dc.getWidth()/2-half,beast.min(dc.getWidth()/2+half,cx));
        gameBounds[0]=(cx-size/2).toNumber();gameBounds[1]=top;gameBounds[2]=size;gameBounds[3]=size;
        dc.drawBitmap(gameBounds[0],top,bitmap);
    }
    function drawArrow(dc,x,top,move,chosen){
        var rows=move==0?[8,28,62,8,8,8,8]:(move==1?[0,28,62,62,62,28,0]:[8,8,8,8,62,28,8]);
        var scale=beast.max(2,(dc.getWidth()/140).toNumber());x-=(7*scale-14)/2;
        if(chosen){dc.setColor(LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillRoundedRectangle(x-7,top-6,7*scale+14,7*scale+14,5);}
        pixelIcon(dc,x,top,rows,INK,scale);
    }
    function drawMap(dc){
        var color=[0x005500,0xAA0000,0x0055AA,0x5500AA][trail];
        var ground=y(dc,0.66);dc.setColor(color,Graphics.COLOR_TRANSPARENT);
        for(var i=0;i<3;i++){
            var x=dc.getWidth()*(0.29+i*0.21);dc.drawCircle(x,ground,6);
            if(i<2){dc.drawLine(x+6,ground,x+dc.getWidth()*0.21-6,ground);}
        }
        // A visible goal, rather than an abstract reward dispenser.
        var iconScale=beast.max(2,(dc.getWidth()/140).toNumber());
        pixelIcon(dc,dc.getWidth()*0.71-3.5*iconScale,y(dc,0.60),[62,127,65,127,65,65,127],0xAA5500,iconScale);
        dc.setColor(0xFFFF55,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(dc.getWidth()*0.71-1,y(dc,0.60)+6,3,4);
        var progress=phase==5?beast.min(1.0,travel/12.0):1.0;
        var cx=dc.getWidth()*(0.29+0.21*beast.max(0,node-1)+0.21*(node>0?progress:0));
        drawPlayer(dc,cx,ground-8,phase==5?tick%2:5,phase==5 && tick%2==0?3:0);
        // Family environments: leaves, lava sparks, waves, stars.
        pixelIcon(dc,dc.getWidth()/2+40,y(dc,0.31),trail==0?[8,28,62,127,62,28,8]:(trail==1?[8,12,28,62,127,62,28]:(trail==2?[8,8,28,28,62,62,28]:[8,8,127,62,28,54,65])),color,2);
    }
    function onUpdate(dc){
        touchWidth=dc.getWidth();darkScene=false;dc.setColor(BG,BG);dc.clear();loadSprite();
        devBadge(dc,INK);
        label(dc,y(dc,0.12),["BEAST BOUNCE","FOLLOW ME","TINY TRAIL"][kind],Graphics.FONT_XTINY);
        if(phase==0){
            label(dc,y(dc,0.25),kind==2?"< "+["GROVE","EMBER","TIDE","WISP"][trail]+" >":(kind==0?"SELECT: HOP":"COPY YOUR BEAST"),Graphics.FONT_XTINY);
            drawPlayer(dc,dc.getWidth()/2,y(dc,0.65),beast.number("motion")>0 && tick%12<2?4:0,0);
            label(dc,y(dc,0.66),kind==2?((tick/8)%2==0?"1 ENERGY = 1 TRIP":"CARE/PLAY EARNS IT"):(kind==0?(scanning?"MENU / TOUCH: MOVE":"UP / DOWN: MOVE"):(scanning?"SELECT: GLOW":"UP / SELECT / DOWN")),Graphics.FONT_XTINY);
            label(dc,y(dc,0.76),kind==2?(beast.number("adventure")>0?"ENERGY "+beast.number("adventure"):"SCOUT: NO LOOT"):(beast.number("games")>=3?"FREE PRACTICE":(beast.number("easy")==1?"< EASY >":"< NORMAL >")),Graphics.FONT_XTINY);
            var paused=beast.data["sessions"][kind]!=null;
            label(dc,y(dc,0.86),paused?"RESUME":"START",Graphics.FONT_XTINY);
        }else if(phase==3){
            label(dc,y(dc,0.25),result,Graphics.FONT_XTINY);
            drawPlayer(dc,dc.getWidth()/2,y(dc,0.66),beast.number("motion")==0?0:(tick%8<4?4:1),beast.number("motion")==2 && tick%8<4?5:0);
            label(dc,y(dc,0.65),resultDetail(),Graphics.FONT_XTINY);
            label(dc,y(dc,0.75),(resultChoice==0?"> ":"")+(kind==2?"ANOTHER TRIP":"PLAY AGAIN"),Graphics.FONT_XTINY);
            label(dc,y(dc,0.86),(resultChoice==1?"> ":"")+"EXIT",Graphics.FONT_XTINY);
        }else if(kind==0){
            label(dc,y(dc,0.23),"ROUND "+(round+1)+"/3  SCORE "+score,Graphics.FONT_XTINY);
            var ground=y(dc,0.71);var cx=dc.getWidth()*(0.29+lane*0.21);
            for(var i=0;i<3;i++){dc.setColor(i==lane?INK:LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(dc.getWidth()*(0.29+i*0.21)-14,ground,28,4);}
            var jumpIndex=beast.min(7,(jumpTicks*7.0/jumpDuration()).toNumber());
            var lift=jumpTicks>0?[0,8,18,27,27,18,8,0][jumpIndex]*dc.getWidth()/280.0:0;
            drawPlayer(dc,cx,ground,jumpTicks>0?1:(caught?4:0),lift);
            if(!caught){var scale=beast.max(2,(dc.getWidth()/140).toNumber());pixelIcon(dc,dc.getWidth()*(0.29+target*0.21)-3.5*scale,y(dc,0.33)+dc.getHeight()*0.29*starPosition(),[8,8,127,62,28,54,65],INK,scale);}
            label(dc,y(dc,0.74),caught?hint:"SELECT: HOP!",Graphics.FONT_XTINY);
            label(dc,y(dc,0.85),hits+" / "+attempts+" STARS",Graphics.FONT_XTINY);
        }else if(kind==1){
            label(dc,y(dc,0.23),"ROUND "+(round+1)+"/3  "+(phase==1?"WATCH":(scanning?"SELECT":"YOUR TURN")),Graphics.FONT_XTINY);
            var move=phase==1?displayedMove():(cursor>0?sequence[cursor-1]:1);
            var lift=move==0?12:(move==2?0:5);
            drawPlayer(dc,dc.getWidth()/2+(move<0?0:(move-1)*12),y(dc,0.66),move<0?0:(move==0?1:(move==1?4:5)),move<0?0:lift);
            for(var i=0;i<3;i++){drawArrow(dc,dc.getWidth()/2+(i-1)*42-7,y(dc,0.70),i,phase==1?move==i:(scanning && (tick/6)%3==i));}
            label(dc,y(dc,0.83),phase==4?hint:(phase==1?"WATCH":cursor+"/"+sequence.size()+"  TRY "+(retries+1)+"/2"),Graphics.FONT_XTINY);
        }else{
            label(dc,y(dc,0.23),["GROVE","EMBER","TIDE","WISP"][trail]+"  STOP "+(node+1)+"/3",Graphics.FONT_XTINY);
            drawMap(dc);
            if(phase==2){
                label(dc,y(dc,0.675),[["HELP A FRIEND","SEARCH THE CAVE","FOLLOW BUBBLES","FOLLOW A WISP"],["CROSS THE BRIDGE","CLIMB THE RIDGE","CHECK THE REEF","READ THE RUNES"],["OPEN THE CHEST","OPEN THE CHEST","OPEN THE CHEST","OPEN THE CHEST"]][node][trail],Graphics.FONT_XTINY);
                label(dc,y(dc,0.775),trailChoice(),Graphics.FONT_XTINY);
                label(dc,y(dc,0.875),"GO",Graphics.FONT_XTINY);
            }else{label(dc,y(dc,0.76),phase==4?hint:"EXPLORING...",Graphics.FONT_XTINY);}
        }
    }
}
