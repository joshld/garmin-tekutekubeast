using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Application.Storage;
using Toybox.System;
using Toybox.Time;

// Isolated SDK-only fixture ID, never a user-facing Developer Mode app.
// Native SDK Steps Progress / Sleep / Wake events execute the UNMODIFIED
// production service under the device's actual background VM budget.
class BackgroundAuditView extends WatchUi.View {
    var model;
    function initialize(){View.initialize();System.println("BACKGROUND_LAUNCH: loading fixture");model=new TekuTekuBeastState();model.start();
        if(Storage.getValue("backgroundFixture")!=1){
            model.data["xp"]=123456l;model.data["birthEpoch"]=model.now()-50*86400;
            model.data["birth"]=model.dateKey(new Time.Moment(model.data["birthEpoch"].toNumber()));
            model.data["stageFloor"]=5;model.data["family"]=4;model.data["rare"]=1;
            model.data["collection"]=15;model.data["rareCollection"]=15;model.data["adventure"]=3;
            model.data["items"]=[11,12,13,14,15,16,17,18];
            for(var i=0;i<32;i++){
                var day=model.dateKey(new Time.Moment((model.now()-i*86400).toNumber()));
                model.data["days"][day%32]=day;model.data["counts"][day%32]=i==0?model.getTodaySteps():10000+i;
            }
            for(var kind=0;kind<3;kind++){
                var session=model.beginSession(kind);
                session["sequence"]=[0,1,2,1,0];session["round"]=2;session["elapsed"]=7;
                session["hint"]="NEXT ROUND";session["lane"]=2;session["target"]=2;
                session["jump"]=4;session["caught"]=true;session["retry"]=false;
                model.saveSession(session);
            }
            model.commit();Storage.setValue("backgroundFixture",1);
        }
        System.println("BACKGROUND_FIXTURE: xp="+model.xp()+" pending="+pending()+" inventory="+model.data["items"][7]);
    }
    function pending(){var count=0;for(var i=0;i<3;i++){if(model.data["sessions"][i]!=null){count++;}}return count;}
    function onUpdate(dc){dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);dc.clear();
        dc.drawText(dc.getWidth()/2,dc.getHeight()*0.25,Graphics.FONT_XTINY,"BACKGROUND QA",Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth()/2,dc.getHeight()*0.45,Graphics.FONT_XTINY,"XP "+model.xp(),Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth()/2,dc.getHeight()*0.60,Graphics.FONT_XTINY,"PENDING "+pending(),Graphics.TEXT_JUSTIFY_CENTER);
    }
}
(:background,:glance)
class BackgroundAuditApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){
        registerSteps();
        System.println("CALLBACK_POLICY: deferred="+BeastCompatibility.deferred()+" steps="+Toybox.Background.getStepsEventRegistered());
        // QA only: recreate an old registration to test its safe upgrade exit.
        if(BeastCompatibility.deferred()){Toybox.Background.registerForStepsEvent();}
        return [new BackgroundAuditView()];
    }
}
