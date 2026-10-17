using Toybox.Application;
using Toybox.Background;

(:background)
module BeastCompatibility {
    function deferred(){return Application.loadResource(Rez.Strings.DeferredActivity).equals("1");}
    function clearCallbacks(){
        // Also remove registrations left by an older version. No save deletion.
        if(Background.getStepsEventRegistered()){Background.deleteStepsEvent();}
        if((Background has :getSleepEventRegistered) && Background.getSleepEventRegistered()){Background.deleteSleepEvent();}
        if((Background has :getWakeEventRegistered) && Background.getWakeEventRegistered()){Background.deleteWakeEvent();}
    }
}
