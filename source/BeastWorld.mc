using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Position;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Weather;

// Separate, small foreground preference/cache record: no pet migration, no
// location payload in the strictly budgeted background or native Glance VM.
class BeastWorld {
    var prefs;var persisted=null;var store;var dev=false;var theme=-1;var checked=0l;
    var cacheKey=null;var days=null;var sample=[1,0.5,true];var minute=-1l;var activeDay=1;
    var source="FIXED 06-18";var preview=-1;var computations=0;
    var draftLat=0.0;var draftLon=0.0;
    function initialize(beast){
        store=beast.store;dev=beast.dev;var saved=store.read("world.v1");
        prefs=saved==null?{}:store.copy(saved);
        var defaults={"environment"=>0,"locationMode"=>0,"lat"=>null,"lon"=>null,"at"=>0l,"manualLat"=>0.0,"manualLon"=>0.0,"manualSet"=>0};
        var keys=defaults.keys();for(var i=0;i<keys.size();i++){if(!prefs.hasKey(keys[i])){prefs[keys[i]]=defaults[keys[i]];}}
        persisted=store.copy(saved);
        draftLat=prefs["manualLat"];draftLon=prefs["manualLon"];
    }
    function save(){if(!dev && !store.same(persisted,prefs)){var document=store.copy(prefs);store.write("world.v1",document);persisted=document;}}
    function invalidate(){cacheKey=null;minute=-1l;}
    function choose(family,day){
        // Locked until an explicit setting change or a new full-app session.
        if(theme<0){theme=prefs["environment"]>0?prefs["environment"]-1:(family>0?family-1:day%4);}return theme;
    }
    function setTheme(value){prefs["environment"]=value;theme=-1;save();}
    function confirmManual(){
        // Editing is a foreground-only draft. Changing another setting or
        // waiting for a sky refresh must not apply/save unconfirmed coordinates.
        if(!BeastSky.valid(draftLat,draftLon)){return false;}
        prefs["manualLat"]=draftLat;prefs["manualLon"]=draftLon;
        prefs["locationMode"]=2;prefs["manualSet"]=1;invalidate();save();return true;
    }
    function accept(lat,lon,at){
        if(!BeastSky.valid(lat,lon)){return false;}
        var roundedLat=Math.round(lat*100)/100.0;var roundedLon=Math.round(lon*100)/100.0;
        var moved=prefs["lat"]!=roundedLat || prefs["lon"]!=roundedLon;
        prefs["lat"]=roundedLat;prefs["lon"]=roundedLon;prefs["at"]=at;
        if(moved){invalidate();}save();return true;
    }
    function readWatch(now,skip){
        if(skip || dev || prefs["locationMode"]!=0 || (checked>0 && now-checked>=0 && now-checked<300)){return;}
        checked=now;
        var found=false;
        try{
            // A read, not LOCATION_CONTINUOUS/ONE_SHOT: never switches on GPS.
            var info=Position.getInfo();
            if(info!=null && info.position!=null && info.accuracy!=Position.QUALITY_NOT_AVAILABLE){
                var c=info.position.toDegrees();
                if(BeastSky.valid(c[0],c[1])){prefs["locationSource"]="SAVED LOCATION";found=accept(c[0],c[1],info.when==null?0l:info.when.value().toLong());}
            }
        }catch(e instanceof Lang.Exception){} // denied/unavailable: retain last good position
        if(!found){
            try{
                // Read an ALREADY CACHED observation, never request a forecast
                // or phone connection. A station location is approximate.
                var weather=Weather.getCurrentConditions();
                if(weather!=null && weather.observationLocationPosition!=null && weather.observationTime!=null){
                    var at=weather.observationTime.value().toLong();var c=weather.observationLocationPosition.toDegrees();
                    if(now>=at && now-at<=604800 && (prefs["lat"]==null || at>=prefs["at"]) && BeastSky.valid(c[0],c[1])){
                        prefs["locationSource"]="WEATHER CACHE";accept(c[0],c[1],at);
                    }
                }
            }catch(e instanceof Lang.Exception){}
        }
    }
    function update(now,nativeApi){
        var m=(now/60).toLong();if(m==minute){return sample;}minute=m;
        if(dev && preview>=0){sample=[preview,preview==2?0.95:(preview==0?0.05:0.5),preview<3];return sample;}
        var date=BeastSky.localDate(now);var zone=BeastSky.offset(now);
        var mode=prefs["locationMode"];var lat=prefs["lat"];var lon=prefs["lon"];
        if(mode==2){lat=prefs["manualSet"]==1?prefs["manualLat"]:null;lon=prefs["manualLon"];}
        if(mode==3){lat=null;lon=null;}
        var key=date+":"+zone+":"+lat+":"+lon+":"+mode;
        if(cacheKey==null || !cacheKey.equals(key)){
            cacheKey=key;computations++;
            if(BeastSky.valid(lat,lon)){
                source=mode==2?"APPROX LOCATION":(mode==0 && prefs.hasKey("locationSource")?prefs["locationSource"]:"SAVED LOCATION");
                // Persisted solar cache survives reopening; only a changed
                // local date, zone or selected position causes recalculation.
                if(prefs.hasKey("solarKey") && prefs["solarKey"].equals(key)){days=prefs["solarDays"];}
                else{days=[BeastSky.events(date-86400,lat,lon,nativeApi),BeastSky.events(date,lat,lon,nativeApi),BeastSky.events(date+86400,lat,lon,nativeApi)];
                    prefs["solarKey"]=key;prefs["solarDays"]=days;save();}
            }else{
                source="FIXED 06-18";var local=date-zone;
                days=[[local-86400+21600,local-86400+64800,0],[local+21600,local+64800,0],[local+86400+21600,local+86400+64800,0]];
            }
        }
        activeDay=BeastSky.chooseDay(now,days);
        var previous=activeDay>0?days[activeDay-1]:[0l,0l,-1];var next=activeDay<2?days[activeDay+1]:[0l,0l,1];
        sample=BeastSky.sample(now,days[activeDay],previous,next);return sample;
    }
    function eventText(index){
        if(days==null){return "--:--";}if(days[activeDay][2]!=0){return days[activeDay][2]==1?"POLAR DAY":"POLAR NIGHT";}
        var t=Gregorian.info(new Time.Moment(days[activeDay][index].toNumber()),Time.FORMAT_SHORT);return t.hour.format("%02d")+":"+t.min.format("%02d");
    }
    function engine(){return days!=null && days[activeDay].size()>3 && days[activeDay][3]==1?"GARMIN SOLAR API":"LOCAL SOLAR / FALLBACK";}
    function fixAge(now){return prefs["at"]>0?"FIX AGE: "+BeastSky.max(0,((now-prefs["at"])/86400).toNumber())+" DAYS":"FIX TIME UNKNOWN";}
}
