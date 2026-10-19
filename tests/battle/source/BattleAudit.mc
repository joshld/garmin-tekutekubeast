using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

// Isolated matrix identity + RAM-only state. Does not touch either real pet.
// Named grids + sequential action/results, identical fighters, replay and KO.
// Set autoExit=false for the interactive report/production battle controls.
class BattleAudit extends BeastBattleView {
    var auditTimer=null;var audited=false;var interactive=false;var cursor=0;
    var failures=[];var boxes=[];var peakMemory=0;var totalMemory=0;var scenes=258;var autoExit=true;
    function initialize(){
        BeastBattleView.initialize(new ArtPreviewState());
        beast.data["sleepMode"]=2;beast.data["sleepUntil"]=0l;
        beast.data["energy"]=80;beast.data["happiness"]=90;beast.data["motion"]=2;
    }
    function onShow(){
        if(interactive){BeastBattleView.onShow();return;}
        auditTimer=new Toybox.Timer.Timer();auditTimer.start(method(:auditRefresh),70,true);
    }
    function onHide(){
        if(auditTimer!=null){auditTimer.stop();auditTimer=null;}
        BeastBattleView.onHide();
    }
    function auditRefresh() as Void {WatchUi.requestUpdate();}
    function fighterForm(form){
        var stage=form<2?form+1:3+beast.min(2,(form-2)%4);
        var family=form<2?0:1+((form-2)/4).toNumber();
        var rare=form>=2 && (form-2)%4==3?1:0;
        return BeastBattleRules.fighter(stage,family,rare,85,[2,3,4,5],160,null);
    }
    function capture(box,value){
        if(!box[4].equals(value)){failures.add("Truncated scene "+cursor+": "+value);}
        boxes.add(box);
    }
    function label(dc,top,value,font){
        var box=BeastBattleView.label(dc,top,value,font);if(!audited){capture(box,value);}return box;
    }
    function battleText(dc,x,top,width,text){
        var lines=BeastBattleView.battleText(dc,x,top,width,text);
        if(!audited){
            if(lines.size()>2){failures.add("More than two lines scene "+cursor+": "+text);}
            var recovered="";
            for(var i=0;i<lines.size();i++){
                if(i>0){recovered+=" ";}recovered+=lines[i];
                var w=dc.getTextWidthInPixels(lines[i],moveFont);
                if(w>width){failures.add("Wrap width scene "+cursor+": "+text);}
                capture([x-w/2,top+i*dc.getFontHeight(moveFont),w,dc.getFontHeight(moveFont),lines[i]],lines[i]);
            }
            if(!recovered.equals(text)){failures.add("Missing move text scene "+cursor+": "+text);}
        }
        return lines;
    }
    function hpBar(dc,x,top,width,index){
        BeastBattleView.hpBar(dc,x,top,width,index);
        if(!audited){
            var text=displayHp(index)+"/"+battle["actors"][index]["maxHp"];var w=dc.getTextWidthInPixels(text,Graphics.FONT_XTINY);
            boxes.add([x+width/2-w/2,top+7,w,dc.getFontHeight(Graphics.FONT_XTINY),"HP "+text]);
        }
    }
    function battleSprite(dc,index){
        BeastBattleView.battleSprite(dc,index);
        if(!audited && battlePictures!=null){
            var pose=battlePose(index);
            var box=battleSpriteBox(dc,index,battlePictures[index][pose],battleBump(index));
            boxes.add([box[0],box[1],box[2],box[3],"Fighter "+index]);
        }
    }
    function checkScene(dc){
        var radius=dc.getWidth()/2-8;var cx=dc.getWidth()/2;var cy=dc.getHeight()/2;
        for(var i=0;i<boxes.size();i++){
            var b=boxes[i];
            for(var corner=0;corner<4;corner++){
                var px=b[0]+(corner%2==0?0:b[2]);var py=b[1]+(corner<2?0:b[3]);
                if((px-cx)*(px-cx)+(py-cy)*(py-cy)>radius*radius){failures.add("Circle scene "+cursor+": "+b[4]);break;}
            }
            for(var j=0;j<i;j++){
                var a=boxes[j];
                if(b[0]<a[0]+a[2] && b[0]+b[2]>a[0] && b[1]<a[1]+a[3] && b[1]+b[3]>a[1]){
                    failures.add("Overlap scene "+cursor+": "+b[4]+" / "+a[4]);
                }
            }
        }
    }
    function fixture(){
        replaying=false;
        if(cursor>=100){feedbackFixture();return;}
        var form=cursor<72?(cursor/4).toNumber():(cursor<90?cursor-72:0);
        var player=fighterForm(form);var foe=fighterForm((form+5)%18);
        battle=BeastBattleRules.create(1,17,player,foe);battlePhase=1;moveChoice=cursor%4;
        battleSleeping=false;battleNotice="";battleResult="+20 BATTLE XP";burst=0;beast.data["motion"]=2;
        if(cursor>=72 && cursor<90){
            battlePhase=2;burst=4;
            battle["events"]=[{"actor"=>0,"move"=>BeastBattleMoves.id(form,1),"damage"=>0,"effect"=>1},
                {"actor"=>1,"move"=>BeastBattleMoves.id(foe["form"],2),"damage"=>0,"effect"=>2}];
        }else if(cursor>=90 && cursor<93){battlePhase=3;battle["status"]=cursor-89;}
        else if(cursor==93){battleSleeping=true;}
        else if(cursor==94){battleNotice="Technique recovering";}
        else if(cursor==95){battle=null;}
        else if(cursor>=96){
            battlePhase=2;burst=1+(cursor-96)%4;beast.data["motion"]=(cursor-96)%3;
            battle["events"]=[{"actor"=>0,"move"=>3,"damage"=>16,"effect"=>3},
                {"actor"=>1,"move"=>foe["form"]*4,"damage"=>7,"effect"=>0}];
        }
    }
    function feedbackFixture(){
        var sample=cursor-100;var form=sample<144?(sample/8).toNumber():1;
        var slot=sample<144?((sample%8)/2).toNumber():(sample<152?(sample-144)/4:0).toNumber();
        var player=fighterForm(form);var foe=fighterForm(form); // identical art/stats
        battle=BeastBattleRules.create(1,17,player,foe);battlePhase=2;
        battleSleeping=false;battleNotice="";battleResult="+12 BATTLE XP";
        beast.data["motion"]=sample%3;burst=sample<144?(sample%2==0?4:3):4-(sample-144)%4;
        replaying=sample>=144 && sample<152;
        var enemySlot=(slot+1)%4;
        battle["events"]=[{"actor"=>0,"move"=>form*4+slot,"damage"=>slot==1 || slot==2?0:12,"effect"=>slot},
            {"actor"=>1,"move"=>form*4+enemySlot,"damage"=>enemySlot==1 || enemySlot==2?0:11,"effect"=>enemySlot}];
        battle["actors"][1]["hp"]-=battle["events"][0]["damage"];
        battle["actors"][0]["hp"]-=battle["events"][1]["damage"];
        if(sample>=152 && sample<156){
            // Presentation-only fallback; v1 rules do not generate heals/misses.
            battle["events"][0]["damage"]=sample<154?-5:0;
            battle["actors"][0]["hp"]=30;battle["actors"][1]["hp"]=30;burst=sample%2==0?4:3;
        }
        if(sample>=156){
            battle["status"]=1;battle["events"]=[battle["events"][0]];
            battle["actors"][1]["hp"]=0;burst=sample==156?2:1;
        }
    }
    function runAudit(dc){
        fixture();boxes=[];BeastBattleView.onUpdate(dc);checkScene(dc);
        var stats=System.getSystemStats();if(stats.usedMemory>peakMemory){peakMemory=stats.usedMemory;}totalMemory=stats.totalMemory;
        cursor++;
        if(cursor>=scenes){
            audited=true;auditTimer.stop();
            System.println("BATTLE_LAYOUT: "+cursor+" scenes; "+failures.size()+" failures");
            System.println("BATTLE_MEMORY: peak="+peakMemory+" total="+totalMemory);
            for(var i=0;i<failures.size();i++){System.println(failures[i]);}
            if(autoExit){auditTimer.start(method(:exitAudit),100,false);}
            WatchUi.requestUpdate();
        }
    }
    function exitAudit() as Void {System.exit();}
    function onUpdate(dc){
        if(!audited){runAudit(dc);return;}
        if(interactive){BeastBattleView.onUpdate(dc);return;}
        dc.setColor(BG,BG);dc.clear();
        label(dc,y(dc,0.18),"BATTLE LAYOUT AUDIT",Graphics.FONT_XTINY);
        label(dc,y(dc,0.35),failures.size()==0?"PASS":"FAIL",Graphics.FONT_LARGE);
        label(dc,y(dc,0.58),cursor+" SCENES",Graphics.FONT_XTINY);
        label(dc,y(dc,0.72),failures.size()+" OVERLAPS / CLIPS",Graphics.FONT_XTINY);
    }
    function selectAction(){
        // SELECT may enter a RAM-only manual scenario without repeating the
        // complete layout audit. No summary is printed for a skipped audit.
        if(!audited){audited=true;auditTimer.stop();autoExit=false;}
        if(!interactive){
            interactive=true;var state=beast as ArtPreviewState;state.previewStage=2;state.previewFamily=0;
            beast.data["motion"]=2;fight.data["active"]=null;fight.data["queue"]=[];
            fight.offer(0);fight.offer(2);fight.offer(3);fight.commit();
            battle=null;burst=0;battleVisible=true;battlePhase=0;battleSleeping=false;battleNotice="";
            tuneBattleTimer();WatchUi.requestUpdate();return;
        }
        BeastBattleView.selectAction();
        if(battle!=null){System.println("BATTLE_UI_INPUT: turn="+battle["turn"]+" phase="+battlePhase+" burst="+burst+" at="+System.getTimer());}
    }
    function refresh() as Void {
        BeastBattleView.refresh();
        if(interactive && battle!=null){System.println("BATTLE_UI_STEP: turn="+battle["turn"]+" phase="+battlePhase+" burst="+burst+" YOU="+displayHp(0)+" WILD="+displayHp(1)+" at="+System.getTimer());}
    }
    function back(){if(!interactive){return true;}return BeastBattleView.back();}
    function switchPage(delta){if(interactive){BeastBattleView.switchPage(delta);}}
}
(:background,:glance)
class MatrixApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){var v=new BattleAudit();return [v,new BeastBattleInput(v)];}
}
