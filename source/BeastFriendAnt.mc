using Toybox.Ant;
using Toybox.Lang;
using Toybox.System;

// Foreground-only radio adapter. Protocol reliability belongs to BeastFriendLink.
// Public ANT network, NOT the ANT+ sensor network; no private key or phone relay.
class BeastFriendAnt {
    var listener;var channel=null;var message=null;var outgoing=null;
    var host=false;var opened=false;var status="RADIO OFF";
    function initialize(receive){listener=receive;}
    function supported(){return (Toybox has :Ant) && (Ant has :GenericChannel);}
    function validPayload(payload){
        if(!(payload instanceof Lang.Array) || payload.size()!=8){return false;}
        for(var i=0;i<8;i++){
            var n=payload[i];
            if(!((n instanceof Lang.Number) || (n instanceof Lang.Long)) || n<0 || n>255){return false;}
        }
        return true;
    }
    function open(isHost,deviceNumber){
        close();host=isHost;
        if(!supported()){status="ANT NOT SUPPORTED";return false;}
        if(!((deviceNumber instanceof Lang.Number) || (deviceNumber instanceof Lang.Long)) || deviceNumber<1 || deviceNumber>65535){status="INVALID PAIR CODE";return false;}
        try{
            var assignment=new Ant.ChannelAssignment(host?Ant.CHANNEL_TYPE_TX_NOT_RX:Ant.CHANNEL_TYPE_RX_NOT_TX,Ant.NETWORK_PUBLIC);
            channel=new Ant.GenericChannel(method(:onMessage),assignment);
            var config=new Ant.DeviceConfig({:deviceNumber=>deviceNumber.toNumber(),:deviceType=>117,:transmissionType=>1,
                :messagePeriod=>8192,:radioFrequency=>66,:searchTimeoutLowPriority=>12,:searchTimeoutHighPriority=>0,:searchThreshold=>0});
            if(!channel.setDeviceConfig(config)){fail("ANT CONFIG FAILED");return false;}
            outgoing=[0,0,0,0,0,0,0,0];message=new Ant.Message();message.setPayload(outgoing);
            if(!channel.open()){fail("ANT OPEN FAILED");return false;}
            opened=true;status=host?"HOSTING":"SEARCHING";
            // Prime the master's broadcast buffer; subsequent TX events refresh it.
            if(host && !channel.sendBroadcast(message)){fail("ANT SEND FAILED");return false;}
            return true;
        }catch(e instanceof Lang.Exception){
            System.println("FRIEND_ANT open: "+e.toString());fail("ANT UNAVAILABLE");return false;
        }
    }
    function send(payload){
        if(!opened || channel==null || !validPayload(payload)){return false;}
        // Keep a private fixed-size buffer: callers may reuse their packet array.
        for(var i=0;i<8;i++){outgoing[i]=payload[i].toNumber();}
        return true;
    }
    function transmit(){
        if(!opened || channel==null){return;}
        try{
            message.setPayload(outgoing);
            var sent=host?channel.sendBroadcast(message):channel.sendAcknowledge(message);
            if(!sent){status="ANT RETRY";}
        }catch(e instanceof Lang.Exception){
            System.println("FRIEND_ANT send: "+e.toString());fail("ANT SEND ERROR");
        }
    }
    function onMessage(msg) as Void {
        if(!opened || channel==null){return;}
        var id=msg.messageId;var payload=msg.getPayload();if(!(payload instanceof Lang.Array)){return;}
        if(id==Ant.MSG_ID_BROADCAST_DATA || id==Ant.MSG_ID_ACKNOWLEDGED_DATA){
            if(!(payload instanceof Lang.Array) || payload.size()!=8){return;}
            // ANT owns the buffer; detach and normalize possible signed bytes.
            var packet=[0,0,0,0,0,0,0,0];
            for(var i=0;i<8;i++){
                var n=payload[i];
                if(!((n instanceof Lang.Number) || (n instanceof Lang.Long)) || n< -128 || n>255){return;}
                packet[i]=n.toNumber()&0xFF;
            }
            status="CONNECTED";listener.invoke(packet);
            // A bidirectional slave returns one cached packet in the master's slot.
            // This also carries application ACKs while no new user move is pending.
            if(!host){transmit();}
            return;
        }
        if(id!=Ant.MSG_ID_CHANNEL_RESPONSE_EVENT || payload.size()<2){return;}
        var original=payload[0]&0xFF;var event=payload[1]&0xFF;
        if(original!=Ant.MSG_ID_RF_EVENT){
            if(event==Ant.MSG_CODE_TRANSFER_IN_PROGRESS){status="ANT RETRY";}
            else if(event!=Ant.MSG_CODE_RESPONSE_NO_ERROR){
                System.println("FRIEND_ANT response: message="+original+" code="+event);fail("ANT CHANNEL ERROR");
            }
            return;
        }
        if(event==Ant.MSG_CODE_EVENT_TX && host){transmit();}
        else if(event==Ant.MSG_CODE_EVENT_RX_SEARCH_TIMEOUT){fail("ANT SEARCH TIMED OUT");}
        else if(event==Ant.MSG_CODE_EVENT_CHANNEL_CLOSED){fail("ANT CONNECTION CLOSED");}
        else if(event==Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH){status="RECONNECTING";}
        else if(event==Ant.MSG_CODE_EVENT_TRANSFER_TX_FAILED || event==Ant.MSG_CODE_EVENT_QUE_OVERFLOW){status="ANT RETRY";}
        else if(event==Ant.MSG_CODE_EVENT_CONNECTION_REJECTED){fail("ANT CONNECTION REJECTED");}
    }
    function fail(reason){close();status=reason;System.println("FRIEND_ANT: "+reason);}
    function close(){
        // Explicit release prevents inactive/active auto-reopen retaining a radio.
        opened=false;var old=channel;channel=null;message=null;outgoing=null;
        status="RADIO OFF";
        if(old!=null){
            try{
                if(!old.release()){
                    // A bounded fallback closes the radio even if unassignment
                    // initially reports an in-flight transfer/state change.
                    old.close();
                    if(!old.release()){status="ANT RELEASE FAILED";System.println("FRIEND_ANT: "+status);}
                }
            }catch(e instanceof Lang.Exception){status="ANT CLOSE ERROR";System.println("FRIEND_ANT release: "+e.toString());}
        }
    }
}
