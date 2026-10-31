using Toybox.Communications;
using Toybox.Lang;
// Foreground-only, one request per launch and at most one attempt per 24h.
class BeastUpdates {
    const URL="https://raw.githubusercontent.com/joshld/garmin-tekutekubeast/main/updates/versions.json";
    const KEY="updates.v1";
    var store;var installed;var channel;var state;var started=false;var offered=false;var pending=false;var listener;var review=true;var readable=true;
    function initialize(storage,version,releaseChannel,ready){
        store=storage;installed=version;channel=releaseChannel;listener=ready;
        var saved=null;try{saved=store.read(KEY);}catch(e instanceof Lang.Exception){readable=false;}state=BeastUpdateRules.clean(saved);
    }
    function persist(next){
        if(store.same(state,next)){return true;}
        try{store.write(KEY,store.copy(next));state=next;return true;}catch(e instanceof Lang.Exception){return false;}
    }
    function start(now){
        if(started || !readable){return;}started=true;
        if(!BeastUpdateRules.timestamp(now) || now<=0 || (state["checked"]>0 && now-state["checked"]<BeastUpdateRules.DAY)){return;}
        var next=store.copy(state);next["checked"]=now.toLong();if(!persist(next)){return;}
        pending=true;try{request();}catch(e instanceof Lang.Exception){pending=false;}
    }
    function request(){
        Communications.makeWebRequest(URL,null,{:method=>Communications.HTTP_REQUEST_METHOD_GET,
            :responseType=>Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON},method(:received));
    }
    function received(code,data) as Void {
        if(!pending){return;}pending=false;if(code!=200){return;}
        var latest=BeastUpdateRules.release(data,channel);if(latest==null){return;}
        // Do not regress the cached release on stale CDN responses.
        if(BeastUpdateRules.parse(state["available"])!=null && BeastUpdateRules.compare(latest,state["available"])<0){return;}
        var next=store.copy(state);next["available"]=latest;
        if(persist(next)){review=true;if(listener!=null){listener.invoke();}}
    }
    function offer(now){if(offered || !review){return null;}review=false;if(!BeastUpdateRules.due(state,installed,now)){return null;}offered=true;return state["available"];}
    function dismiss(version,choice,now){
        if(BeastUpdateRules.parse(version)==null || !BeastUpdateRules.timestamp(now) || (choice!=0 && choice!=1)){return;}
        var next=store.copy(state);
        if(choice==1){next["ignored"]=version;}else{next["later"]=version;next["remindAt"]=now+BeastUpdateRules.DAY;}
        persist(next);
    }
}
