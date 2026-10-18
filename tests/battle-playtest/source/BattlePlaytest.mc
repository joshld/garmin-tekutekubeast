using Toybox.Application;
using Toybox.Application.Storage;
using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;

// Isolated matrix UUID. Pet fixtures stay in RAM; only QA battle records and
// the fixture selection persist. Never installs over either production app.
class PlaytestStore extends BeastStore {
    var fixture;
    function initialize(index){BeastStore.initialize();memory={};fixture=index;}
    function read(key){
        if(key.equals("battle.v1")){return Storage.getValue("qa.battle."+fixture);}
        return BeastStore.read(key);
    }
    function write(key,value){
        if(key.equals("battle.v1")){Storage.setValue("qa.battle."+fixture,value);return true;}
        return BeastStore.write(key,value);
    }
}

// Use the actual transaction code, including atomic Storage serialization,
// without enabling writes to the RAM-only Developer Mode pet fixture.
class PlaytestBattle extends BeastBattle {
    function initialize(model){BeastBattle.initialize(model);}
    function commit(){
        var original=beast.dev;beast.dev=false;BeastBattle.commit();beast.dev=original;
    }
}

class PlaytestBattleView extends BeastBattleView {
    var fixture;
    function initialize(index){
        fixture=index;var model=new ArtPreviewState();
        model.previewStage=index<2?index+1:(index==2?3:(index==3?4:5));
        model.previewFamily=index<2?0:index-1;
        model.store=new PlaytestStore(index);model.battleData=null;
        model.data["sleepMode"]=2;model.data["sleepUntil"]=0l;
        model.data["friendship"]=85;model.data["personality"]=[2,3,4,5];
        model.data["energy"]=80;model.data["happiness"]=90;model.data["motion"]=2;
        BeastBattleView.initialize(model);model.battleData=null;fight=new PlaytestBattle(model);
        if(fight.battleQueueCount()==0){fight.offer(2);fight.commit();}
        System.println("BATTLE_PLAYTEST fixture="+index+" stage="+model.stage()+" family="+model.family());
    }
    function onHide(){
        if(battle!=null){System.println("BATTLE_PLAYTEST fixture="+fixture+" turn="+battle["turn"]+" status="+battle["status"]+" xp="+fight.battleXp()+" seed="+battle["seed"]);}
        BeastBattleView.onHide();
    }
}

class BattleFixtureChooser extends TekuTekuBeastView {
    var choice=0;
    var choices=["CONTINUE LAST","PIP","NIMBLE","ADULT GROVE","CHAMPION EMBER","LEGENDARY TIDE","LEGENDARY WISP"];
    function initialize(){TekuTekuBeastView.initialize();beast=new ArtPreviewState();}
    function onShow(){Application.getApp().activeView=self;WatchUi.requestUpdate();}
    function onHide(){}
    function switchPage(delta){choice=(choice+delta+choices.size())%choices.size();WatchUi.requestUpdate();}
    function selectAction(){
        var index=choice==0?Storage.getValue("qa.fixture"):choice-1;
        if(index==null || index<0 || index>5){index=0;}
        Storage.setValue("qa.fixture",index);
        var view=new PlaytestBattleView(index);
        WatchUi.pushView(view,new BeastBattleInput(view),WatchUi.SLIDE_LEFT);
    }
    function back(){System.exit();return true;}
    function touch(point){selectAction();}
    function onUpdate(dc){
        dc.setColor(BG,BG);dc.clear();
        label(dc,y(dc,0.12),"BATTLE PLAYTEST",Graphics.FONT_XTINY);
        label(dc,y(dc,0.27),choices[(choice+choices.size()-1)%choices.size()],Graphics.FONT_XTINY);
        label(dc,y(dc,0.42),choices[choice],Graphics.FONT_SMALL);
        label(dc,y(dc,0.59),choices[(choice+1)%choices.size()],Graphics.FONT_XTINY);
        label(dc,y(dc,0.75),"UP / DOWN: FIXTURE",Graphics.FONT_XTINY);
        label(dc,y(dc,0.86),"SELECT: OPEN",Graphics.FONT_XTINY);
    }
}

(:background,:glance)
class MatrixApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){var view=new BattleFixtureChooser();return [view,new TekuTekuBeastInput(view)];}
}
