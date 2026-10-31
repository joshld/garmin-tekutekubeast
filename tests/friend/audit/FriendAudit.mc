using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
class FriendAudit extends BeastFriendView {
    var cursor=0;var failures;var boxes;var done=false;var auditTimer;var peakMemory=0;var totalMemory=0;
    function initialize(){
        var model=new ArtPreviewState();BeastFriendView.initialize(model);failures=[];boxes=[];
        model.data["sleepMode"]=2;model.data["sleepUntil"]=0l;model.data["motion"]=2;
    }
    function onShow(){auditTimer=new Toybox.Timer.Timer();auditTimer.start(method(:drawNext),70,true);}
    function onHide(){if(auditTimer!=null){auditTimer.stop();}BeastFriendView.onHide();}
    function drawNext() as Void {WatchUi.requestUpdate();}
    function actor(form){
        var stage=form<2?form+1:3+beast.min(2,(form-2)%4);var family=form<2?0:1+((form-2)/4).toNumber();
        return BeastBattleRules.fighter(stage,family,form>=2 && (form-2)%4==3?1:0,85,[1,2,3,4],240,null);
    }
    function capture(box,value){
        if(!box[4].equals(value)){failures.add("Truncated scene "+cursor+": "+value);}
        boxes.add(box);
    }
    function label(dc,top,value,font){
        var box=BeastBattleView.label(dc,top,value,font);if(!done){capture(box,value);}return box;
    }
    function battleText(dc,x,top,width,text){
        var lines=BeastBattleView.battleText(dc,x,top,width,text);
        if(!done){
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
    function fighterLabel(dc,index){
        BeastBattleView.fighterLabel(dc,index);
        if(!done && !compactGrid && battlePhase==2 && burst>0 && battle["events"][eventIndex()]["actor"]==index){
            boxes.add([dc.getWidth()*fighterLabelPosition(index)-16,y(dc,dc.getWidth()<240?0.14:0.125)+dc.getFontHeight(moveFont),32,1,"Active fighter"]);
        }
    }
    function hpBar(dc,x,top,width,index){
        BeastBattleView.hpBar(dc,x,top,width,index);
        if(!done){
            var text=displayHp(index)+"/"+battle["actors"][index]["maxHp"];var font=hpFont(dc,top,index);var w=dc.getTextWidthInPixels(text,font);
            if(dc.getWidth()>=240){boxes.add([hpInline(dc,top,index)?x+width-w:x+width/2-w/2,hpInline(dc,top,index)?top:top+7,w,dc.getFontHeight(font),"HP "+text]);}
            var barWidth=!hpInline(dc,top,index) || dc.getWidth()<240?width:width-w-4;
            if(barWidth<3){failures.add("HP bar too narrow scene "+cursor);}
            boxes.add([x,!hpInline(dc,top,index) || dc.getWidth()<240?top:top+7,barWidth,6,"HP bar "+index]);
        }
    }
    function battleSprite(dc,index){
        BeastBattleView.battleSprite(dc,index);
        if(!done && battlePictures!=null){
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
        paused=false;resumeTicks=0;battleSleeping=false;battleNotice="";burst=0;battle=null;battlePhase=1;
        if(cursor<4){link=null;role=cursor%2;entering=cursor>=2;digit=cursor%4;return;}
        role=cursor%2;pairCode=1234;link=new BeastFriendLink(role==0,12,0,actor(1),0);
        if(cursor<8){
            if(cursor==6){link.phase="EXCHANGE";}else if(cursor==7){link.phase="CLOSED";link.reason="INTERRUPTED - RECONNECT";}return;
        }
        var offset=cursor-8;var form=(offset/20).toNumber();var mode=(offset/2).toNumber()%10;
        link.remoteActor=actor(form);link.localActor=actor(form);link.phase="PLAY";link.battle=link.startState();
        battle=displayState(link.battle);moveChoice=mode%4;
        if(mode==4){link.phase="READY";}else if(mode==5){link.choice=3;}else if(mode==6){link.phase="TURN";link.choice=0;}
        else if(mode>=7){
            link.battle=BeastBattleRules.pairedTurn(link.battle,mode==9?3:1,mode==9?0:2);battle=displayState(link.battle);
            link.phase="PRESENT";battlePhase=2;burst=mode==7?4:(mode==8?3:1);
        }
    }
    function onUpdate(dc){
        if(done){return;}fixture();boxes=[];BeastFriendView.onUpdate(dc);checkScene(dc);
        var stats=System.getSystemStats();peakMemory=beast.max(peakMemory,stats.usedMemory);totalMemory=stats.totalMemory;cursor++;
        if(cursor>=368){
            done=true;auditTimer.stop();System.println("FRIEND_LAYOUT scenes="+cursor+" failures="+failures.size());
            for(var i=0;i<beast.min(16,failures.size());i++){System.println(failures[i]);}
            System.println("FRIEND_MEMORY sampled="+peakMemory+" total="+totalMemory);
            auditTimer.start(method(:finish),100,false);
        }
    }
    function finish() as Void {System.exit();}
}
(:background,:glance)
class MatrixApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){var view=new FriendAudit();return [view,new BeastBattleInput(view)];}
}