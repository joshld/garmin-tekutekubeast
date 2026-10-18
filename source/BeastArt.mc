using Toybox.WatchUi;
// Generated asset catalog: cache only the current creature's six frames.
class BeastArt {
    function initialize() {}
    // Native poses are not consistently oriented across the original atlas.
    // Bit 0/1 marks a right-facing walk pose; reuse the two existing mirrors.
    static function walkFrame(stage,family,pose,left){
        var rightMask=0;
        if(stage==5 && family==1){rightMask=3;}
        else if((stage==4 && (family==1 || family==3 || family==4)) ||
                (stage==3 && family==3) || (stage==5 && family==4)){rightMask=2;}
        var nativeRight=(rightMask&(1<<pose))!=0;
        return pose+(left==nativeRight?6:0);
    }
    function petFrames(stage,family){
        if(stage==0){var egg=WatchUi.loadResource(Rez.Drawables.V5Egg0);return [egg,egg,egg,egg,egg,egg,egg,egg];}
        var ids=[
            [Rez.Drawables.V5Egg0,Rez.Drawables.V5Egg0,Rez.Drawables.V5Egg0,Rez.Drawables.V5Egg0,Rez.Drawables.V5Egg0,Rez.Drawables.V5Egg0,Rez.Drawables.V5Egg0,Rez.Drawables.V5Egg0Left],
            [Rez.Drawables.V5Pip0,Rez.Drawables.V5Pip1,Rez.Drawables.V5Pip2,Rez.Drawables.V5Pip3,Rez.Drawables.V5Pip4,Rez.Drawables.V5Pip5,Rez.Drawables.V5Pip0Left,Rez.Drawables.V5Pip1Left],
            [Rez.Drawables.V5Nimble0,Rez.Drawables.V5Nimble1,Rez.Drawables.V5Nimble2,Rez.Drawables.V5Nimble3,Rez.Drawables.V5Nimble4,Rez.Drawables.V5Nimble5,Rez.Drawables.V5Nimble0Left,Rez.Drawables.V5Nimble1Left],
            [Rez.Drawables.V5Grove30,Rez.Drawables.V5Grove31,Rez.Drawables.V5Grove32,Rez.Drawables.V5Grove33,Rez.Drawables.V5Grove34,Rez.Drawables.V5Grove35,Rez.Drawables.V5Grove30Left,Rez.Drawables.V5Grove31Left],
            [Rez.Drawables.V5Grove40,Rez.Drawables.V5Grove41,Rez.Drawables.V5Grove42,Rez.Drawables.V5Grove43,Rez.Drawables.V5Grove44,Rez.Drawables.V5Grove45,Rez.Drawables.V5Grove40Left,Rez.Drawables.V5Grove41Left],
            [Rez.Drawables.V5Grove50,Rez.Drawables.V5Grove51,Rez.Drawables.V5Grove52,Rez.Drawables.V5Grove53,Rez.Drawables.V5Grove54,Rez.Drawables.V5Grove55,Rez.Drawables.V5Grove50Left,Rez.Drawables.V5Grove51Left],
            [Rez.Drawables.V5Ember30,Rez.Drawables.V5Ember31,Rez.Drawables.V5Ember32,Rez.Drawables.V5Ember33,Rez.Drawables.V5Ember34,Rez.Drawables.V5Ember35,Rez.Drawables.V5Ember30Left,Rez.Drawables.V5Ember31Left],
            [Rez.Drawables.V5Ember40,Rez.Drawables.V5Ember41,Rez.Drawables.V5Ember42,Rez.Drawables.V5Ember43,Rez.Drawables.V5Ember44,Rez.Drawables.V5Ember45,Rez.Drawables.V5Ember40Left,Rez.Drawables.V5Ember41Left],
            [Rez.Drawables.V5Ember50,Rez.Drawables.V5Ember51,Rez.Drawables.V5Ember52,Rez.Drawables.V5Ember53,Rez.Drawables.V5Ember54,Rez.Drawables.V5Ember55,Rez.Drawables.V5Ember50Left,Rez.Drawables.V5Ember51Left],
            [Rez.Drawables.V5Tide30,Rez.Drawables.V5Tide31,Rez.Drawables.V5Tide32,Rez.Drawables.V5Tide33,Rez.Drawables.V5Tide34,Rez.Drawables.V5Tide35,Rez.Drawables.V5Tide30Left,Rez.Drawables.V5Tide31Left],
            [Rez.Drawables.V5Tide40,Rez.Drawables.V5Tide41,Rez.Drawables.V5Tide42,Rez.Drawables.V5Tide43,Rez.Drawables.V5Tide44,Rez.Drawables.V5Tide45,Rez.Drawables.V5Tide40Left,Rez.Drawables.V5Tide41Left],
            [Rez.Drawables.V5Tide50,Rez.Drawables.V5Tide51,Rez.Drawables.V5Tide52,Rez.Drawables.V5Tide53,Rez.Drawables.V5Tide54,Rez.Drawables.V5Tide55,Rez.Drawables.V5Tide50Left,Rez.Drawables.V5Tide51Left],
            [Rez.Drawables.V5Wisp30,Rez.Drawables.V5Wisp31,Rez.Drawables.V5Wisp32,Rez.Drawables.V5Wisp33,Rez.Drawables.V5Wisp34,Rez.Drawables.V5Wisp35,Rez.Drawables.V5Wisp30Left,Rez.Drawables.V5Wisp31Left],
            [Rez.Drawables.V5Wisp40,Rez.Drawables.V5Wisp41,Rez.Drawables.V5Wisp42,Rez.Drawables.V5Wisp43,Rez.Drawables.V5Wisp44,Rez.Drawables.V5Wisp45,Rez.Drawables.V5Wisp40Left,Rez.Drawables.V5Wisp41Left],
            [Rez.Drawables.V5Wisp50,Rez.Drawables.V5Wisp51,Rez.Drawables.V5Wisp52,Rez.Drawables.V5Wisp53,Rez.Drawables.V5Wisp54,Rez.Drawables.V5Wisp55,Rez.Drawables.V5Wisp50Left,Rez.Drawables.V5Wisp51Left]];
        var selected=ids[index(stage,family)];var result=[];
        for(var i=0;i<8;i++){result.add(WatchUi.loadResource(selected[i]));}return result;
    }
    function index(stage,family){return stage<3?stage:3+(family-1)*3+stage-3;}
    function frames(stage,family){
        if(stage==0){var egg=WatchUi.loadResource(Rez.Drawables.V5GameEgg0);return [egg,egg,egg,egg,egg,egg];}
        var ids=[[Rez.Drawables.V5GameEgg0,Rez.Drawables.V5GameEgg0,Rez.Drawables.V5GameEgg0,Rez.Drawables.V5GameEgg0,Rez.Drawables.V5GameEgg0,Rez.Drawables.V5GameEgg0],
            [Rez.Drawables.V5GamePip0,Rez.Drawables.V5GamePip1,Rez.Drawables.V5GamePip2,Rez.Drawables.V5GamePip3,Rez.Drawables.V5GamePip4,Rez.Drawables.V5GamePip5],
            [Rez.Drawables.V5GameNimble0,Rez.Drawables.V5GameNimble1,Rez.Drawables.V5GameNimble2,Rez.Drawables.V5GameNimble3,Rez.Drawables.V5GameNimble4,Rez.Drawables.V5GameNimble5],
            [Rez.Drawables.V5GameGrove30,Rez.Drawables.V5GameGrove31,Rez.Drawables.V5GameGrove32,Rez.Drawables.V5GameGrove33,Rez.Drawables.V5GameGrove34,Rez.Drawables.V5GameGrove35],
            [Rez.Drawables.V5GameGrove40,Rez.Drawables.V5GameGrove41,Rez.Drawables.V5GameGrove42,Rez.Drawables.V5GameGrove43,Rez.Drawables.V5GameGrove44,Rez.Drawables.V5GameGrove45],
            [Rez.Drawables.V5GameGrove50,Rez.Drawables.V5GameGrove51,Rez.Drawables.V5GameGrove52,Rez.Drawables.V5GameGrove53,Rez.Drawables.V5GameGrove54,Rez.Drawables.V5GameGrove55],
            [Rez.Drawables.V5GameEmber30,Rez.Drawables.V5GameEmber31,Rez.Drawables.V5GameEmber32,Rez.Drawables.V5GameEmber33,Rez.Drawables.V5GameEmber34,Rez.Drawables.V5GameEmber35],
            [Rez.Drawables.V5GameEmber40,Rez.Drawables.V5GameEmber41,Rez.Drawables.V5GameEmber42,Rez.Drawables.V5GameEmber43,Rez.Drawables.V5GameEmber44,Rez.Drawables.V5GameEmber45],
            [Rez.Drawables.V5GameEmber50,Rez.Drawables.V5GameEmber51,Rez.Drawables.V5GameEmber52,Rez.Drawables.V5GameEmber53,Rez.Drawables.V5GameEmber54,Rez.Drawables.V5GameEmber55],
            [Rez.Drawables.V5GameTide30,Rez.Drawables.V5GameTide31,Rez.Drawables.V5GameTide32,Rez.Drawables.V5GameTide33,Rez.Drawables.V5GameTide34,Rez.Drawables.V5GameTide35],
            [Rez.Drawables.V5GameTide40,Rez.Drawables.V5GameTide41,Rez.Drawables.V5GameTide42,Rez.Drawables.V5GameTide43,Rez.Drawables.V5GameTide44,Rez.Drawables.V5GameTide45],
            [Rez.Drawables.V5GameTide50,Rez.Drawables.V5GameTide51,Rez.Drawables.V5GameTide52,Rez.Drawables.V5GameTide53,Rez.Drawables.V5GameTide54,Rez.Drawables.V5GameTide55],
            [Rez.Drawables.V5GameWisp30,Rez.Drawables.V5GameWisp31,Rez.Drawables.V5GameWisp32,Rez.Drawables.V5GameWisp33,Rez.Drawables.V5GameWisp34,Rez.Drawables.V5GameWisp35],
            [Rez.Drawables.V5GameWisp40,Rez.Drawables.V5GameWisp41,Rez.Drawables.V5GameWisp42,Rez.Drawables.V5GameWisp43,Rez.Drawables.V5GameWisp44,Rez.Drawables.V5GameWisp45],
            [Rez.Drawables.V5GameWisp50,Rez.Drawables.V5GameWisp51,Rez.Drawables.V5GameWisp52,Rez.Drawables.V5GameWisp53,Rez.Drawables.V5GameWisp54,Rez.Drawables.V5GameWisp55]];
        var selected=ids[index(stage,family)];var result=[];
        for(var i=0;i<6;i++){result.add(WatchUi.loadResource(selected[i]));}return result;
    }
}
