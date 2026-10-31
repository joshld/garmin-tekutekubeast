// Portable eight-byte friend framing; never clocks, radio, storage or rewards.
module BeastFriendWire {
    const MAGIC=0xB1;
    // First two SHA-256 bytes (big endian) of canonical battle-v1.json:
    // JSON sort_keys=True, separators=(",", ":"), ensure_ascii=True, UTF-8.
    const ENGINE_TAG=24773;
    function frame(sid,seq,op,a,b){
        if(!BeastBattleRules.integer(sid,0,16777215) || !BeastBattleRules.integer(seq,0,240) ||
            !BeastBattleRules.integer(op,0,23) || !BeastBattleRules.integer(a,0,255) || !BeastBattleRules.integer(b,0,255)){return null;}
        sid=sid.toNumber();return [MAGIC,op.toNumber(),sid&255,(sid>>8)&255,(sid>>16)&255,seq.toNumber(),a.toNumber(),b.toNumber()];
    }
    function decode(packet){
        if(!BeastBattleRules.intArray(packet,8,0,255) || packet[0]!=MAGIC || packet[1]>23 || packet[5]>240){return null;}
        return [packet[2].toNumber()+(packet[3].toNumber()<<8)+(packet[4].toNumber()<<16),packet[5].toNumber(),packet[1].toNumber(),packet[6].toNumber(),packet[7].toNumber()];
    }
    function actor(bytes){
        if(!BeastBattleRules.intArray(bytes,12,0,255) || bytes[0]>17 || bytes[1]>100 || bytes[2]>3 || bytes[3]>BeastBattleData.LEVEL_CAP){return null;}
        var form=bytes[0].toNumber();var family=0;var stage=form+1;var rare=0;
        if(form>=2){var variant=(form-2)%4;family=1+((form-2)/4).toNumber();rare=variant==3?1:0;stage=variant==3?5:variant+3;}
        var trained=[];
        for(var i=4;i<12;i+=2){
            var mastery=bytes[i].toNumber()+(bytes[i+1].toNumber()<<8);
            if(mastery>BeastBattleData.MASTERY_CAP){return null;}trained.add(mastery);
        }
        var temper=[0,0,0,0];temper[bytes[2].toNumber()]=1;
        var result=BeastBattleRules.fighter(stage,family,rare,bytes[1].toNumber(),temper,bytes[3].toNumber()*BeastBattleData.LEVEL_XP,null);
        result["mastery"]=trained;return result;
    }
    function actorBytes(value){
        if(!BeastBattleRules.validActor(value)){return null;}
        var level=value["maxHp"]-BeastBattleData.HP_BASE-value["stage"]*BeastBattleData.HP_STAGE;
        if(!BeastBattleRules.integer(level,0,BeastBattleData.LEVEL_CAP)){return null;}
        var result=[value["form"],value["friendship"],value["temper"],level];
        for(var i=0;i<4;i++){var n=value["mastery"][i].toNumber();result.add(n&255);result.add((n>>8)&255);}
        var normalized=actor(result);if(normalized==null){return null;}
        var keys=["form","family","stage","maxHp","hp","power","armour","friendship","temper","guard","buff","cooldown"];
        for(var k=0;k<keys.size();k++){if(value[keys[k]]!=normalized[keys[k]]){return null;}}
        return result;
    }
    function fold(hash,value){return (hash*17+value)%65521;}
    function digest(state){
        var hash=state["id"]%65521;var keys=["seed","turn","status"];
        for(var i=0;i<keys.size();i++){hash=fold(hash,state[keys[i]]);}
        keys=["form","family","stage","maxHp","hp","power","armour","friendship","temper","guard","buff","cooldown"];
        for(var a=0;a<2;a++){
            var fighter=state["actors"][a];for(var k=0;k<keys.size();k++){hash=fold(hash,fighter[keys[k]]);}
            for(var m=0;m<4;m++){hash=fold(hash,fighter["mastery"][m]);}
        }
        for(var u=0;u<4;u++){hash=fold(hash,state["uses"][u]);}
        hash=fold(hash,state["events"].size());
        for(var e=0;e<state["events"].size();e++){
            var event=state["events"][e];hash=fold(hash,event["actor"]);hash=fold(hash,event["move"]);
            hash=fold(hash,event["damage"]);hash=fold(hash,event["effect"]);
        }
        return hash.toNumber();
    }
    function flags(actor){return actor["guard"]+2*actor["buff"]+8*actor["cooldown"];}
    function resultBytes(state,first,second){
        if(!BeastBattleRules.versioned(state) || !BeastBattleRules.integer(first,0,3) || !BeastBattleRules.integer(second,0,3)){return null;}
        var hash=digest(state);var a=state["actors"];
        return [state["turn"],first.toNumber()|(second.toNumber()<<2),a[0]["hp"],a[1]["hp"],state["seed"]&255,(state["seed"]>>8)&255,
            state["status"],flags(a[0]),flags(a[1]),hash&255,(hash>>8)&255,0];
    }
    function result(prior,bytes,ownJoinChoice){
        if(!BeastBattleRules.intArray(bytes,12,0,255) || bytes[11]!=0 || bytes[1]>15 ||
            !BeastBattleRules.integer(ownJoinChoice,0,3)){return null;}
        var safe=BeastBattleRules.exportState(prior);if(safe==null || bytes[0]!=safe["turn"]+1){return null;}
        var first=bytes[1].toNumber()&3;var second=(bytes[1].toNumber()>>2)&3;
        if(second!=ownJoinChoice || !BeastBattleRules.availableAt(safe,0,first) || !BeastBattleRules.availableAt(safe,1,second)){return null;}
        var candidate=BeastBattleRules.pairedTurn(safe,first,second);var expected=resultBytes(candidate,first,second);
        for(var i=0;i<12;i++){if(bytes[i]!=expected[i]){return null;}}
        return candidate;
    }
}
