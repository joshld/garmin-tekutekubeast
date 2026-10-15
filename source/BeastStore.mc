using Toybox.Application.Storage;
using Toybox.Lang;
// A single atomic document owns each save. Legacy keys are never deleted.
(:background)
class BeastStore {
    var memory = null;
    function initialize() {}
    function read(key) {
        if(memory!=null){return memory.hasKey(key)?memory[key]:null;}
        return Storage.getValue(key);
    }
    function write(key,value) {
        if(memory!=null){memory[key]=value;}else{Storage.setValue(key,value);}
    }
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
