// Pure, bounded stop-and-wait protocol. Time is supplied by the foreground.
// No Garmin APIs, persistent pet state or rewards. Host is canonical actor zero.
class BeastFriendLink {
    var host;var sid;var token;var localActor;var remoteActor=null;
    var phase="SEARCH";var reason="";var battle=null;var candidate=null;
    var localReady=false;var remoteReady=false;var choice=-1;var remoteChoice=-1;
    var finalConfirmed=false;var changed=0;var tx=1;var rx=1;
    var pending=null;var queue;var ack=null;var ackUntil=0;var retryAt=0;var attempts=0;
    var lastPacket=null;var lastSeen;var deadline;var clock;var started;var closeAt=0;
    var chunks;var chunkIndex=0;var beacon;var heartbeat=null;var committedAt=0;
    function initialize(isHost,session,challenge,actor,now){
        host=isHost;sid=isHost?session:0;token=challenge;localActor=BeastFriendWire.actor(BeastFriendWire.actorBytes(actor));
        queue=[];chunks=[];clock=now;started=now;lastSeen=now;deadline=now+45000;
        beacon=BeastFriendWire.frame(sid,0,1,BeastFriendWire.ENGINE_TAG&255,(BeastFriendWire.ENGINE_TAG>>8)&255);
        if(localActor==null || (host && sid<1)){fail("INVALID BEAST",now);}
    }
    function transition(value,now){phase=value;deadline=now+90000;changed++;}
    function enqueue(op,a,b){if(queue.size()>=10 || tx>240){return false;}queue.add([op,a,b]);return true;}
    function bytes(op,values){for(var i=0;i<12;i+=2){if(!enqueue(op+i/2,values[i],values[i+1])){return false;}}return true;}
    function seed(){return ((sid%65521)*17+token)%65521;}
    function actors(){return host?[localActor,remoteActor]:[remoteActor,localActor];}
    function pairDigest(){var a=actors();return BeastFriendWire.digest(BeastBattleRules.create(sid,seed(),a[0],a[1]));}
    function startState(){var a=actors();return BeastBattleRules.create(sid,seed(),a[0],a[1]);}
    function ready(now){
        if(!phase.equals("READY") || localReady){return false;}
        var hash=pairDigest();localReady=true;enqueue(10,hash&255,(hash>>8)&255);changed++;maybeStart(now);return true;
    }
    function maybeStart(now){
        if(host && phase.equals("READY") && localReady && remoteReady){battle=startState();enqueue(11,seed()&255,(seed()>>8)&255);transition("START",now);}
    }
    function choose(slot,now){
        if(!phase.equals("PLAY") || choice>=0 || !BeastBattleRules.availableAt(battle,host?0:1,slot)){return false;}
        choice=slot;changed++;
        if(host){resolve(now);}else{enqueue(12,battle["turn"],slot);}return true;
    }
    function resolve(now){
        if(!host || !phase.equals("PLAY") || choice<0 || remoteChoice<0){return;}
        candidate=BeastBattleRules.pairedTurn(battle,choice,remoteChoice);
        bytes(13,BeastFriendWire.resultBytes(candidate,choice,remoteChoice));transition("TURN",now);
    }
    function commitTurn(now){
        battle=candidate;candidate=null;choice=-1;remoteChoice=-1;committedAt=now;transition("PRESENT",now);
    }
    function presentationDone(now){
        if(!phase.equals("PRESENT")){return;}
        if(battle["status"]==0){transition("PLAY",now);}else if(finalConfirmed){transition("RESULT",now);}
    }
    function fail(text,now){reason=text;transition("CLOSED",now);closeAt=now;pending=null;queue=[];}
    function cancel(now){
        if(phase.equals("CLOSED") || phase.equals("CLOSING")){return;}
        reason="BATTLE CANCELLED";pending=null;queue=[];enqueue(22,0,0);transition("CLOSING",now);closeAt=now+2000;
    }
    function tick(now){
        if(now<clock){fail("CLOCK CHANGED",now);return;}clock=now;
        if(phase.equals("CLOSED")){return;}
        if(phase.equals("CLOSING")){if(now>=closeAt){fail(reason,now);}return;}
        if(phase.equals("RESULT")) {return;}
        if(now>=deadline || now-started>600000){cancel(now);reason="BATTLE TIMED OUT";return;}
        if(!phase.equals("SEARCH") && now-lastSeen>12000){fail("CONNECTION LOST",now);return;}
        if(pending!=null && now>=retryAt){
            if(attempts>=12){fail("CONNECTION LOST",now);return;}
            attempts++;retryAt=now+750;
        }
    }
    function next(now){
        tick(now);if(phase.equals("CLOSED")){return null;}
        if(ack!=null && now<ackUntil){return ack;}
        if(pending==null && queue.size()>0){
            var part=queue[0];queue.remove(part);pending=BeastFriendWire.frame(sid,tx,part[0],part[1],part[2]);tx++;attempts=1;retryAt=now+750;
            if(pending==null){fail("SESSION EXHAUSTED",now);return null;}
        }
        if(pending!=null){return pending;}
        if(phase.equals("SEARCH")){return beacon;}
        if(heartbeat==null){heartbeat=BeastFriendWire.frame(sid,0,23,BeastFriendWire.ENGINE_TAG&255,(BeastFriendWire.ENGINE_TAG>>8)&255);}
        return heartbeat;
    }
    function acknowledge(packet,now){ack=BeastFriendWire.frame(sid,packet[1],0,packet[2],0);ackUntil=now+300;}
    function receive(raw,now){
        tick(now);if(phase.equals("CLOSED")){return;}
        var p=BeastFriendWire.decode(raw);if(p==null){return;}
        var incoming=p[0];var seq=p[1];var op=p[2];var a=p[3];var b=p[4];
        if(!host && phase.equals("SEARCH") && op==1 && seq==0 && incoming>0){
            if(a+256*b!=BeastFriendWire.ENGINE_TAG){fail("INCOMPATIBLE VERSION",now);return;}
            sid=incoming;lastSeen=now;enqueue(2,token&255,(token>>8)&255);transition("HELLO",now);return;
        }
        if(incoming!=sid || sid==0){return;}
        // Cancellation ends a session even if an earlier reliable frame was lost.
        if(op==22 && seq>0){accept(op,a,b,now);lastSeen=now;acknowledge(p,now);return;}
        if(op==1 && seq==0){return;}
        if(op==23 && seq==0){if(a+256*b==BeastFriendWire.ENGINE_TAG){lastSeen=now;}return;}
        if(op==0){
            if(pending==null || seq!=pending[5] || a!=pending[1] || b!=0){return;}
            lastSeen=now;var sent=pending[1];pending=null;
            if(sent==11 && host){transition("PLAY",now);}
            else if(sent==20 && host){commitTurn(now);if(battle["status"]!=0){enqueue(21,battle["turn"],BeastFriendWire.digest(battle)&255);}}
            else if(sent==21 && host){finalConfirmed=true;changed++;}
            else if(sent==22){closeAt=now+500;}
            return;
        }
        if(lastPacket!=null && seq==rx-1 && op==lastPacket[2] && a==lastPacket[3] && b==lastPacket[4]){lastSeen=now;acknowledge(p,now);return;}
        if(seq!=rx || seq==0){return;}
        if(!accept(op,a,b,now)){return;}
        lastSeen=now;lastPacket=p;rx++;acknowledge(p,now);
    }
    function accept(op,a,b,now){
        if(op==22){reason="OPPONENT LEFT";pending=null;queue=[];transition("CLOSING",now);closeAt=now+1000;return true;}
        if(host && phase.equals("SEARCH") && op==2){
            token=a+256*b;enqueue(3,a,b);bytes(4,BeastFriendWire.actorBytes(localActor));transition("EXCHANGE",now);return true;
        }
        if(!host && phase.equals("HELLO") && op==3 && a+256*b==token){bytes(4,BeastFriendWire.actorBytes(localActor));transition("EXCHANGE",now);return true;}
        if(phase.equals("EXCHANGE") && op>=4 && op<=9 && op==4+chunkIndex){
            chunks.add(a);chunks.add(b);chunkIndex++;
            if(chunkIndex==6){remoteActor=BeastFriendWire.actor(chunks);chunks=[];chunkIndex=0;
                if(remoteActor==null){fail("INVALID OPPONENT",now);return false;}transition("READY",now);}
            return true;
        }
        if(phase.equals("READY") && op==10 && a+256*b==pairDigest()){remoteReady=true;changed++;maybeStart(now);return true;}
        if(!host && phase.equals("READY") && localReady && remoteReady && op==11 && a+256*b==seed()){
            battle=startState();transition("PLAY",now);return true;
        }
        if(host && (phase.equals("PLAY") || phase.equals("PRESENT")) && op==12 && a==battle["turn"] && remoteChoice<0 && BeastBattleRules.availableAt(battle,1,b)){
            remoteChoice=b;resolve(now);return true;
        }
        if(!host && phase.equals("PLAY") && choice>=0 && op>=13 && op<=18 && op==13+chunkIndex){
            chunks.add(a);chunks.add(b);chunkIndex++;
            if(chunkIndex==6){candidate=BeastFriendWire.result(battle,chunks,choice);chunks=[];chunkIndex=0;
                if(candidate==null){fail("TURN MISMATCH",now);return false;}
                enqueue(19,candidate["turn"],BeastFriendWire.digest(candidate)&255);transition("TURN",now);}
            return true;
        }
        if(host && phase.equals("TURN") && op==19 && a==candidate["turn"] && b==(BeastFriendWire.digest(candidate)&255)){
            enqueue(20,a,b);transition("COMMIT",now);return true;
        }
        if(!host && phase.equals("TURN") && op==20 && a==candidate["turn"] && b==(BeastFriendWire.digest(candidate)&255)){commitTurn(now);return true;}
        if(!host && phase.equals("PRESENT") && op==21 && battle["status"]!=0 && a==battle["turn"] && b==(BeastFriendWire.digest(battle)&255)){finalConfirmed=true;changed++;return true;}
        return false;
    }
}
