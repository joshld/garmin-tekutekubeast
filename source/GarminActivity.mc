using Toybox.ActivityMonitor;

// Optional Garmin fields are normalized here, not in gameplay rules. No GPS,
// storage or new polling: callers retain their existing event cadence.
(:background)
module GarminActivity {
    function info(){return ActivityMonitor.getInfo();}
    function history(){return ActivityMonitor.getHistory();}
    function steps(info){return info==null?null:info.steps;}
    function minutes(info){
        if(info!=null && (info has :activeMinutesDay)){
            var active=info.activeMinutesDay;if(active!=null){return active.moderate+active.vigorous;}}
        return null;
    }
    function pushes(info){return info!=null && (info has :pushes)?info.pushes:null;}
    function todaySteps(){var n=steps(info());return n==null?0:n;}
}
