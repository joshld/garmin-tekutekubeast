using Toybox.Application.Storage;
using Toybox.Lang;
// A single atomic document owns each save. Legacy keys are never deleted.
(:background)
class BeastStore {
    var memory = null;
    var canonical=null;var reads=0;var writes=0;var skipped=0;
    function initialize() {}
    function read(key) {
        reads++;var value=memory!=null?(memory.hasKey(key)?memory[key]:null):Storage.getValue(key);
        // Independent baseline: reading/editing a migration fixture cannot
        // mutate the snapshot used to decide whether persistence is necessary.
        if(key.equals("v4")){canonical=copy(value);}return value;
    }
    function write(key,value) {
        if(key.equals("v4") && same(canonical,value)){skipped++;return false;}
        if(memory!=null){memory[key]=value;}else{Storage.setValue(key,value);}
        writes++;if(key.equals("v4")){canonical=value;}return true;
    }
    function same(a,b){
        if(a instanceof Lang.Dictionary){if(!(b instanceof Lang.Dictionary) || a.size()!=b.size()){return false;}var keys=a.keys();for(var i=0;i<keys.size();i++){if(!b.hasKey(keys[i]) || !same(a[keys[i]],b[keys[i]])){return false;}}return true;}
        if(a instanceof Lang.Array){if(!(b instanceof Lang.Array) || a.size()!=b.size()){return false;}for(var i=0;i<a.size();i++){if(!same(a[i],b[i])){return false;}}return true;}
        if(a instanceof Lang.String){return b instanceof Lang.String && a.equals(b);}return a==b;
    }
    function changed(value){if(same(canonical,value)){skipped++;return false;}return true;}
    function copy(value) {
        if(value instanceof Lang.Dictionary){
            var result={};var keys=value.keys();
            for(var i=0;i<keys.size();i++){result[keys[i]]=copy(value[keys[i]]);}
            return result;
        }
        if(value instanceof Lang.Array){
            var result=[];
            for(var i=0;i<value.size();i++){result.add(copy(value[i]));}
            return result;
        }
        return value;
    }
}
