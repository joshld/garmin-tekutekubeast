using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

// Isolated QA identity / RAM pet. Production game rendering, no game rewards,
// real activity or real save writes. Fourteen non-egg forms.
class GameArtScene extends AuditGame {
    var drawnPose=-1;
    function initialize(b,k,a){AuditGame.initialize(b,k,a);}
    function drawPlayer(dc,cx,ground,pose,hop){
        drawnPose=pose;AuditGame.drawPlayer(dc,cx,ground,pose,hop);
    }
}
class GameArtAudit extends ArtLayoutAuditView {
    var autoExit=true;
    function initialize(){
        TekuTekuBeastView.initialize();beast=new ArtPreviewState();sceneCount=210;
        beast.data["sleepMode"]=2;beast.data["sleepUntil"]=0l;
        beast.data["energy"]=80;beast.data["happiness"]=90;
    }
    function onUpdate(dc){
        if(audited){return;}
        var inBattle=cursor>=168;
        var specimen=inBattle?((cursor-168)/3).toNumber():(cursor/12).toNumber();var scenario=cursor%12;
        var model=beast as ArtPreviewState;
        model.previewStage=specimen<2?specimen+1:3+((specimen-2)%3);
        model.previewFamily=specimen<2?0:1+((specimen-2)/3).toNumber();
        model.data["motion"]=2;
        if(inBattle){renderBattle(dc,model,(cursor-168)%3);}
        else{renderGame(dc,model,specimen,scenario);}
        var stats=System.getSystemStats();if(stats.usedMemory>peakMemory){peakMemory=stats.usedMemory;}
        cursor++;
        if(cursor==sceneCount){
            audited=true;refresher.stop();
            System.println("GAME_ART_AUDIT: scenes="+cursor+" failures="+failures.size()+" sampledPeak="+peakMemory+" total="+stats.totalMemory);
            for(var i=0;i<failures.size();i++){System.println(failures[i]);}
            if(autoExit){refresher.start(method(:finishExit),100,false);}
        }
    }
    function renderBattle(dc,model,pose){
        var view=new BeastBattleView(beast);
        var player=BeastBattleRules.fighter(model.stage(),model.family(),0,80,[2,3,4,5],0,null);
        var foe=BeastBattleRules.fighter(2,0,0,80,[2,3,4,5],0,null);
        view.battle=BeastBattleRules.create(1,17,player,foe);
        view.battlePhase=pose==0?1:(pose==1?2:3);view.burst=pose==1?4:0;
        if(pose==1){view.battle["events"]=[{"actor"=>0,"move"=>player["form"]*4,"damage"=>7,"effect"=>0},{"actor"=>1,"move"=>4,"damage"=>7,"effect"=>0}];}
        if(pose==2){view.battle["status"]=1;view.battleResult="+20 BATTLE XP";}
        view.onUpdate(dc);
        for(var actor=0;actor<2;actor++){
            var bitmap=view.battlePictures[actor][pose==2 && actor==1?0:pose];
            checkGraphic(dc,view.battleSpriteBox(dc,actor,bitmap,pose==1?(actor==0?3:-3):0),"Battle creature");
        }
    }
    function renderGame(dc,model,specimen,scenario){
        var kind=scenario<4?0:(scenario<7?1:2);
        var game=new GameArtScene(beast,kind,self);
        game.phase=scenario==0?0:(scenario==1 || scenario==4 || scenario==5?1:
            (scenario==2 || scenario==3 || scenario==6 || scenario==11?3:(scenario==10?2:5)));
        game.tick=scenario==3?5:scenario%2;
        game.result="WELL PLAYED!";game.hint="GREAT!";game.score=100;
        game.sequence=[0,1,2];game.elapsed=scenario==5?game.tempo():0;
        game.lane=0;game.jumpTicks=scenario==1?4:0;
        game.trail=specimen%4;game.node=scenario==9?2:1;game.travel=scenario%2==0?8:3;
        boxes=[];game.onUpdate(dc);checkScene(dc);checkGraphic(dc,game.gameBounds,"Game creature");
        if(game.phase==5){
            var expected=BeastArt.trailFrame(model.stage(),model.family(),game.tick%2);
            // Renderer frame selection is captured independently of the helper.
            if(game.drawnPose!=expected){failures.add("Adventure facing "+cursor);}
        }
    }
}
(:background,:glance)
class MatrixApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){var view=new GameArtAudit();return [view,new TekuTekuBeastInput(view)];}
}
