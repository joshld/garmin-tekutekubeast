using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Math;
using Toybox.Weather;
using Toybox.Position;
using Toybox.Lang;

// Foreground only. Absolute epochs prevent watch-zone/DST double offsets.
module BeastSky {
    const RAD=0.017453292519943295;
    function min(a,b){return a<b?a:b;}function max(a,b){return a>b?a:b;}
    function abs(v){return v<0?-v:v;}
    // Concrete return types avoid SDK 9.2's combinatorial Float/Double inference
    // on the longer NOAA series, while retaining normal compiler type checking.
    function sine(v as Lang.Float) as Lang.Float {return Math.sin(v).toFloat();}
    function cosine(v as Lang.Float) as Lang.Float {return Math.cos(v).toFloat();}
    function valid(lat,lon){return lat!=null && lon!=null && lat>=-90 && lat<=90 && lon>=-180 && lon<=180;}
    function midnight(year,month,day){return Gregorian.moment({:year=>year,:month=>month,:day=>day,:hour=>0,:minute=>0,:second=>0}).value().toLong();}
    function localDate(now){var d=Gregorian.info(new Time.Moment(now.toNumber()),Time.FORMAT_SHORT);return midnight(d.year,d.month,d.day);}
    function offset(now){var d=Gregorian.info(new Time.Moment(now.toNumber()),Time.FORMAT_SHORT);return midnight(d.year,d.month,d.day)+d.hour*3600+d.min*60+d.sec-now;}
    // NOAA fractional-year approximation, apparent horizon 90.833 degrees.
    // Returns [rise UTC, set UTC, polar: -1 night / 0 normal / 1 day].
    function calculate(date as Lang.Long,lat as Lang.Float,lon as Lang.Float) as Lang.Array {
        var d=Gregorian.utcInfo(new Time.Moment(date.toNumber()),Time.FORMAT_SHORT);
        var doy=(date-midnight(d.year,1,1))/86400+1;
        var leap=d.year%4==0 && (d.year%100!=0 || d.year%400==0);
        var g=2*Math.PI*(doy-1)/(leap?366.0:365.0);
        var eq=229.18*(0.000075+0.001868*cosine(g)-0.032077*sine(g)-0.014615*cosine(2*g)-0.040849*sine(2*g));
        var dec=0.006918-0.399912*cosine(g)+0.070257*sine(g)-0.006758*cosine(2*g)+0.000907*sine(2*g)-0.002697*cosine(3*g)+0.00148*sine(3*g);
        // Clamp poles just inside 90 to avoid division by zero.
        var a=max(-89.999,min(89.999,lat))*RAD;
        var h=(cosine(90.833*RAD)-sine(a)*sine(dec))/(cosine(a)*cosine(dec));
        if(h>1){return [0l,0l,-1];}if(h< -1){return [0l,0l,1];}
        var span=Math.acos(h)/RAD*4;
        var noon=720-4*lon-eq;
        return [date+((noon-span)*60).toLong(),date+((noon+span)*60).toLong(),0];
    }
    function events(date,lat,lon,nativeApi){
        var result=calculate(date,lat,lon);
        if(result[2]!=0 || !nativeApi){return result;}
        if((Weather has :getSunrise) && (Weather has :getSunset)){
            try{
                var loc=new Position.Location({:latitude=>lat,:longitude=>lon,:format=>:degrees});
                // Noon UTC is only a calendar-date carrier, not watch local time.
                var when=new Time.Moment((date+43200).toNumber());
                var rise=Weather.getSunrise(loc,when);var set=Weather.getSunset(loc,when);
                if(rise!=null && set!=null){
                    var r=rise.value().toLong();var s=set.value().toLong();
                    // Some firmware interprets the date carrier differently.
                    // Reject wrong-date or implausible results, never shift twice.
                    if(s>r && s-r<86400 && abs(r-result[0])<7200 && abs(s-result[1])<7200){return [r,s,0,1];}
                }
            }catch(e instanceof Lang.Exception){}
        }
        return result;
    }
    function clamp(v){return max(0.0,min(1.0,v));}
    function chooseDay(now,days){
        // The selected/cached location may be in a different zone from the
        // watch (travel, retained fix, or manual coordinates). Choose absolute
        // events bracketing NOW, not blindly the middle calendar-date tuple.
        if(days[1][2]!=0){return 1;}
        for(var i=0;i<3;i++){if(days[i][2]==0 && now>=days[i][0] && now<days[i][1]){return i;}}
        for(var i=0;i<3;i++){if(days[i][2]==0 && now<days[i][0]){return i;}}return 2;
    }
    // phase: 0 dawn, 1 day, 2 dusk, 3 night. Moon is decorative night progress.
    function sample(now,events,previous,next){
        if(events[2]!=0){return [events[2]==1?1:3,0.5,events[2]==1];}
        var rise=events[0];var set=events[1];var daylight=now>=rise && now<set;
        var phase=daylight?1:3;
        var nearRise=!daylight && now>=set && next[2]==0?next[0]:rise;
        var nearSet=!daylight && now<rise && previous[2]==0?previous[1]:set;
        if(abs(now-nearRise)<1800){phase=0;}else if(abs(now-nearSet)<1800){phase=2;}
        var fraction=0.5;
        if(daylight){fraction=clamp((now-rise)/(set-rise).toFloat());}
        else if(now<rise){var last=previous[2]==0?previous[1]:rise-43200;fraction=clamp((now-last)/(rise-last).toFloat());}
        else{var following=next[2]==0?next[0]:set+43200;fraction=clamp((now-set)/(following-set).toFloat());}
        return [phase,fraction,daylight];
    }
}
