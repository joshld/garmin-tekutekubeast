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
        refresher=new Toybox.Timer.Timer();refresher.start(method(:refresh),250,true);
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
    }
    function checkpoint(){
        if(session==null || phase==3){return;}
        session["phase"]=phase;session["elapsed"]=elapsed;session["attempts"]=attempts;session["hits"]=hits;
        session["score"]=score;session["combo"]=combo;session["best"]=best;session["round"]=round;
        session["cursor"]=cursor;session["sequence"]=beast.store.copy(sequence);session["retries"]=retries;
        session["route"]=trail;session["node"]=node;session["choice"]=choice;session["travel"]=travel;
        session["lane"]=lane;session["target"]=target;session["jump"]=jumpTicks;session["caught"]=caught;session["retry"]=replayRound;
        session["hint"]=hint;
        beast.saveSession(session);
    }
    function random(limit){session["seed"]=(session["seed"]*17+11)%65521;return session["seed"]%limit;}
    function begin(){
        session=beast.beginSession(kind);if(session==null){result="CARE / PLAY EARNS IT";return;}
        // A paused session is resumed, not replaced or charged twice.
        if(session["elapsed"]>0 || session["node"]>0 || session["sequence"].size()>0 || session["travel"]>0){restore(session);return;}
        phase=kind==2?5:1;round=0;elapsed=0;attempts=0;hits=0;score=0;combo=0;best=0;retries=0;node=0;
        result="";choice=0;resultChoice=0;travel=0;lane=1;jumpTicks=0;caught=false;
        if(kind==0){target=random(3);}
        if(kind==1){makeSequence();}
        checkpoint();
    }
    function makeSequence(){
        sequence=[];for(var i=0;i<3+round;i++){sequence.add(random(3));}
        cursor=0;elapsed=0;phase=1;
    }
    function refresh() as Void {
        tick++;if(phase==1 || phase==2 || phase==4 || phase==5){elapsed++;}
        if(kind==0 && phase==1){
            if(jumpTicks>0){jumpTicks--;}
            var local=elapsed.toFloat()/period();
            if(!caught && jumpTicks>0 && lane==target && local>=0.45 && local<=0.90){
                caught=true;hits++;combo++;best=beast.max(best,combo);score+=10+beast.min(5,combo)*2;
                hint=combo>1?"COMBO "+combo:"GOT IT!";new FeedbackManager().cue(beast,"happy");checkpoint();
            }
            if(elapsed>=period()){catchStar(false);}
        }
        if(kind==1 && phase==1 && elapsed>=sequence.size()*tempo()){phase=2;elapsed=0;cursor=0;checkpoint();}
        if(kind==1 && phase==2 && elapsed>=120){memoryInput(-1);}
        if(kind==1 && phase==4 && elapsed>=12){continueMemory();}
        if(kind==2 && phase==5){travel++;if(travel>=12){phase=2;elapsed=0;travel=0;choice=0;checkpoint();}}
        if(kind==2 && phase==4 && elapsed>=10){nextTrail();}
        WatchUi.requestUpdate();
    }
    function period(){return [20,16,12][round]+(beast.number("easy")==1?4:0);}
    function tempo(){return beast.number("easy")==1?8:6;}
    function starPosition(){return elapsed.toFloat()/period();}
    function catchStar(check){
        // The pet must actually jump into a falling star; input never awards it
        // merely by hitting an invisible timing bar.
        if(check){if(jumpTicks==0){jumpTicks=7;}return;}
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
        session["seed"]=(session["seed"]+trail*97+node*41+choice*211)%65521;
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
        WatchUi.requestUpdate();
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
        if(phase==3){resultChoice=point[1]>touchWidth*0.76?1:0;selectAction();return;}
        if(kind==0 && phase==1){lane=point[0]<touchWidth/3?0:(point[0]>touchWidth*2/3?2:1);selectAction();}
        else if(kind==1 && phase==2){memoryInput(point[0]<touchWidth/3?0:(point[0]>touchWidth*2/3?2:1));WatchUi.requestUpdate();}
        else{selectAction();}
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
        if(chosen){dc.setColor(LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillRoundedRectangle(x-7,top-6,28,28,5);}
        pixelIcon(dc,x,top,rows,INK,2);
    }
    function drawMap(dc){
        var color=[0x005500,0xAA0000,0x0055AA,0x5500AA][trail];
        var ground=y(dc,0.66);dc.setColor(color,Graphics.COLOR_TRANSPARENT);
        for(var i=0;i<3;i++){
            var x=dc.getWidth()*(0.29+i*0.21);dc.drawCircle(x,ground,6);
            if(i<2){dc.drawLine(x+6,ground,x+dc.getWidth()*0.21-6,ground);}
        }
        var progress=phase==5?beast.min(1.0,travel/12.0):1.0;
        var cx=dc.getWidth()*(0.29+0.21*beast.max(0,node-1)+0.21*(node>0?progress:0));
        drawPlayer(dc,cx,ground-8,phase==5?tick%2:5,phase==5 && tick%2==0?3:0);
        // Family environments: leaves, lava sparks, waves, stars.
        pixelIcon(dc,dc.getWidth()/2+40,y(dc,0.31),trail==0?[8,28,62,127,62,28,8]:(trail==1?[8,12,28,62,127,62,28]:(trail==2?[8,8,28,28,62,62,28]:[8,8,127,62,28,54,65])),color,2);
    }
    function onUpdate(dc){
        touchWidth=dc.getWidth();darkScene=false;dc.setColor(BG,BG);dc.clear();loadSprite();
        devBadge(dc,INK);
        label(dc,y(dc,0.12),["BEAST BOUNCE","FOLLOW MY LEAD","TINY TRAIL"][kind],Graphics.FONT_XTINY);
        if(phase==0){
            label(dc,y(dc,0.25),kind==2?"< "+["GROVE","EMBER","TIDE","WISP"][trail]+" >":(kind==0?"SELECT: HOP":"COPY YOUR BEAST"),Graphics.FONT_XTINY);
            drawPlayer(dc,dc.getWidth()/2,y(dc,0.66),tick%12<2?4:0,0);
            label(dc,y(dc,0.68),kind==2?((tick/8)%2==0?"1 ENERGY = 1 TRIP":"CARE/PLAY EARNS IT"):(kind==0?(scanning?"MENU / TOUCH: MOVE":"UP / DOWN: MOVE"):"UP / SELECT / DOWN"),Graphics.FONT_XTINY);
            label(dc,y(dc,0.78),kind==2?(beast.number("adventure")>0?"ENERGY "+beast.number("adventure"):"SCOUT: NO LOOT"):(beast.number("games")>=3?"FREE PRACTICE":(beast.number("easy")==1?"EASY - UP/DOWN":"NORMAL - UP/DOWN")),Graphics.FONT_XTINY);
            var paused=beast.data["sessions"][kind]!=null;
            label(dc,y(dc,0.86),paused?"RESUME":"START",Graphics.FONT_XTINY);
        }else if(phase==3){
            label(dc,y(dc,0.25),result,Graphics.FONT_XTINY);
            drawPlayer(dc,dc.getWidth()/2,y(dc,0.66),tick%2==0?4:1,beast.number("motion")==2 && tick%2==0?5:0);
            label(dc,y(dc,0.67),kind==2?"IN YOUR COLLECTION":"SCORE "+score+"  BEST "+(kind==0?best:hits),Graphics.FONT_XTINY);
            label(dc,y(dc,0.78),(resultChoice==0?"> ":"")+(kind==2?"ANOTHER TRIP":"PLAY AGAIN"),Graphics.FONT_XTINY);
            label(dc,y(dc,0.86),(resultChoice==1?"> ":"")+"EXIT",Graphics.FONT_XTINY);
        }else if(kind==0){
            label(dc,y(dc,0.23),"ROUND "+(round+1)+"/3  SCORE "+score,Graphics.FONT_XTINY);
            var ground=y(dc,0.71);var cx=dc.getWidth()*(0.29+lane*0.21);
            for(var i=0;i<3;i++){dc.setColor(i==lane?INK:LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillRectangle(dc.getWidth()*(0.29+i*0.21)-14,ground,28,4);}
            var lift=jumpTicks>0?[0,8,18,27,27,18,8,0][jumpTicks]*dc.getWidth()/280.0:0;
            drawPlayer(dc,cx,ground,jumpTicks>0?1:(caught?4:0),lift);
            if(!caught){pixelIcon(dc,dc.getWidth()*(0.29+target*0.21)-7,y(dc,0.33)+dc.getHeight()*0.29*starPosition(),[8,8,127,62,28,54,65],INK,2);}
            label(dc,y(dc,0.74),caught?hint:"SELECT: HOP!",Graphics.FONT_XTINY);
            label(dc,y(dc,0.85),hits+" / "+attempts+" STARS",Graphics.FONT_XTINY);
        }else if(kind==1){
            label(dc,y(dc,0.23),"ROUND "+(round+1)+"/3  "+(phase==1?"WATCH":"YOUR TURN"),Graphics.FONT_XTINY);
            var move=phase==1?sequence[beast.min(sequence.size()-1,(elapsed/tempo()).toNumber())]:(cursor>0?sequence[cursor-1]:1);
            var lift=move==0?12:(move==2?0:5);
            drawPlayer(dc,dc.getWidth()/2+(move-1)*12,y(dc,0.66),move==0?1:(move==1?4:5),lift);
            for(var i=0;i<3;i++){drawArrow(dc,dc.getWidth()/2+(i-1)*42-7,y(dc,0.70),i,phase==1?move==i:(scanning && (tick/6)%3==i));}
            label(dc,y(dc,0.83),phase==4?hint:(phase==1?"WATCH":cursor+"/"+sequence.size()+"  TRY "+(retries+1)+"/2"),Graphics.FONT_XTINY);
        }else{
            label(dc,y(dc,0.23),["GROVE","EMBER","TIDE","WISP"][trail]+"  STOP "+(node+1)+"/3",Graphics.FONT_XTINY);
            drawMap(dc);
            if(phase==2){
                label(dc,y(dc,0.70),[["HELP A FRIEND","SEARCH THE CAVE","FOLLOW BUBBLES","FOLLOW A WISP"],["CROSS THE BRIDGE","CLIMB THE RIDGE","CHECK THE REEF","READ THE RUNES"],["OPEN THE CHEST","OPEN THE CHEST","OPEN THE CHEST","OPEN THE CHEST"]][node][trail],Graphics.FONT_XTINY);
                label(dc,y(dc,0.80),choice==0?"> SEARCH":"> DETOUR",Graphics.FONT_XTINY);
                label(dc,y(dc,0.88),"GO",Graphics.FONT_XTINY);
            }else{label(dc,y(dc,0.76),phase==4?hint:"EXPLORING...",Graphics.FONT_XTINY);}
        }
    }
}
