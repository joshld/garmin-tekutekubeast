using Toybox.Background;
using Toybox.System;
using Toybox.Time;
(:background)
class CareBackgroundService extends TekuTekuBeastService {
    function initialize(){TekuTekuBeastService.initialize();}
    function onTemporalEvent(){reconcile(true);}
}
(:background,:glance)
class CareBackgroundApp extends BackgroundAuditApp {
    function initialize(){BackgroundAuditApp.initialize();}
    function getServiceDelegate(){return [new CareBackgroundService()];}
    function getInitialView(){
        var result=BackgroundAuditApp.getInitialView();var m=result[0].model;var t=m.now();
        m.data["energy"]=0;m.data["careAt"]=t-86400;m.data["lastCare"]=t-86400;m.data["lastGrowth"]=t-86400;
        m.data["poop"]=0;m.data["poopSlots"]=0;m.data["poopDue"]=t-1;
        m.data["digestDay"]=m.today();m.data["digestWaste"]=0;m.data["digestRemainder"]=0;m.data["cleanliness"]=100;
        m.data["digestion"]=[t-1,6,0l,0,0l,0,0l,0];m.commit();
        Background.registerForTemporalEvent(Time.now().add(new Time.Duration(1)));
        System.println("CARE_BACKGROUND_SCHEDULED: isolated temporal QA trigger");return result;
    }
    function onStorageChanged(){
        var m=new TekuTekuBeastState();m.start();var count=0;for(var i=0;i<3;i++){if(m.data["sessions"][i]!=null){count++;}}
        if(m.number("poop")!=3 || m.number("digestWaste")!=2){return;}
        System.println("CARE_BACKGROUND_RESULT: xp="+m.xp()+" pending="+count+" inventory="+m.data["items"][7]+" poop="+m.number("poop")+" foodWaste="+m.number("digestWaste"));
        System.exit();
    }
}
