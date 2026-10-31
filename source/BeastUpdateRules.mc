using Toybox.Lang;
// Bounded SemVer 2 comparison and reminder eligibility, independent of the watch.
module BeastUpdateRules {
    const DAY=86400;
    function ascii(c){return c.toCharArray()[0].toNumber();}
    function digit(c){if(c.length()!=1){return false;}var code=ascii(c);return code>=48 && code<=57;}
    function textCompare(a,b){
        var first=a.toCharArray();var second=b.toCharArray();var n=first.size()<second.size()?first.size():second.size();
        for(var i=0;i<n;i++){var x=first[i].toNumber();var y=second[i].toNumber();if(x!=y){return x>y?1:-1;}}
        return first.size()==second.size()?0:(first.size()>second.size()?1:-1);
    }
    function numeric(text){
        if(text.length()==0 || text.length()>9 || (text.length()>1 && text.substring(0,1).equals("0"))){return null;}
        var n=0;for(var i=0;i<text.length();i++){var c=text.substring(i,i+1);if(!digit(c)){return null;}n=n*10+c.toNumber();}return n;
    }
    function parts(text,separator){
        var result=[];var start=0;for(var i=0;i<text.length();i++){if(text.substring(i,i+1).equals(separator)){result.add(text.substring(start,i));start=i+1;}}
        result.add(text.substring(start,text.length()));return result;
    }
    function identifiers(text,prerelease){
        var items=parts(text,".");
        for(var i=0;i<items.size();i++){
            var item=items[i];if(item.length()==0){return null;}var allDigits=true;
            for(var k=0;k<item.length();k++){
                var c=item.substring(k,k+1);var isDigit=digit(c);allDigits=allDigits && isDigit;
                var code=ascii(c);if(!isDigit && !(code>=65 && code<=90) && !(code>=97 && code<=122) && code!=45){return null;}
            }
            if(prerelease && allDigits && item.length()>1 && item.substring(0,1).equals("0")){return null;}
        }return items;
    }
    function parse(value){
        if(!(value instanceof Lang.String) || value.length()<5 || value.length()>32){return null;}
        var build=parts(value,"+");if(build.size()>2 || (build.size()==2 && identifiers(build[1],false)==null)){return null;}
        var release=build[0];var at=-1;for(var i=0;i<release.length();i++){if(release.substring(i,i+1).equals("-")){at=i;break;}}
        var pre=null;if(at>=0){pre=identifiers(release.substring(at+1,release.length()),true);if(pre==null){return null;}release=release.substring(0,at);}
        var core=parts(release,".");if(core.size()!=3){return null;}
        var nums=[];for(var j=0;j<3;j++){var n=numeric(core[j]);if(n==null){return null;}nums.add(n);}return [nums,pre];
    }
    function numberId(text){for(var i=0;i<text.length();i++){if(!digit(text.substring(i,i+1))){return false;}}return true;}
    function compare(first,second){
        var a=parse(first);var b=parse(second);if(a==null || b==null){return null;}
        for(var i=0;i<3;i++){if(a[0][i]!=b[0][i]){return a[0][i]>b[0][i]?1:-1;}}
        var ap=a[1];var bp=b[1];if(ap==null || bp==null){return ap==null?(bp==null?0:1):-1;}
        var n=ap.size()<bp.size()?ap.size():bp.size();
        for(var j=0;j<n;j++){
            if(ap[j].equals(bp[j])){continue;}
            var an=numberId(ap[j]);var bn=numberId(bp[j]);
            if(an!=bn){return an?-1:1;}
            if(an && ap[j].length()!=bp[j].length()){return ap[j].length()>bp[j].length()?1:-1;}
            return textCompare(ap[j],bp[j]);
        }return ap.size()==bp.size()?0:(ap.size()>bp.size()?1:-1);
    }
    function release(data,channel){
        if(!(data instanceof Lang.Dictionary) || !data.hasKey("stable") || !data.hasKey("beta") ||
            parse(data["stable"])==null || parse(data["beta"])==null || data["stable"].length()>20 || data["beta"].length()>20 || (!channel.equals("stable") && !channel.equals("beta"))){return null;}
        return data[channel];
    }
    function timestamp(value){return ((value instanceof Lang.Number) || (value instanceof Lang.Long)) && value>=0 && value<=7258118400l;}
    function clean(saved){
        var state={"checked"=>0l,"available"=>"","ignored"=>"","later"=>"","remindAt"=>0l};
        if(!(saved instanceof Lang.Dictionary)){return state;}
        var keys=["available","ignored","later"];for(var i=0;i<keys.size();i++){var key=keys[i];if(saved.hasKey(key) && parse(saved[key])!=null && saved[key].length()<=20){state[key]=saved[key];}}
        var clocks=["checked","remindAt"];for(var j=0;j<clocks.size();j++){var clock=clocks[j];if(saved.hasKey(clock) && timestamp(saved[clock])){state[clock]=saved[clock].toLong();}}
        return state;
    }
    function due(state,installed,now){
        if(!timestamp(now) || parse(state["available"])==null || compare(state["available"],installed)!=1){return false;}
        if(compare(state["available"],state["ignored"])==0){return false;}
        return compare(state["available"],state["later"])!=0 || now>=state["remindAt"];
    }
}
