using Toybox.WatchUi;
// Generated asset catalog: cache only the current creature's six frames.
class BeastArt {
    function initialize() {}
    function petFrames(stage,family){
        if(stage==0){var egg=WatchUi.loadResource(Rez.Drawables.V5Egg0);return [egg,egg,egg,egg,egg,egg,egg,egg];}
        var ids=[
            [Rez.Drawables.V5Egg0,Rez.Drawables.V5Egg1,Rez.Drawables.V5Egg2,Rez.Drawables.V5Egg3,Rez.Drawables.V5Egg4,Rez.Drawables.V5Egg5,Rez.Drawables.V5Egg0Left,Rez.Drawables.V5Egg1Left],
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
        if(stage==0){var egg=WatchUi.loadResource(Rez.Drawables.V4Egg0);return [egg,egg,egg,egg,egg,egg];}
        var ids=[[Rez.Drawables.V4Egg0,Rez.Drawables.V4Egg1,Rez.Drawables.V4Egg2,Rez.Drawables.V4Egg3,Rez.Drawables.V4Egg4,Rez.Drawables.V4Egg5],
            [Rez.Drawables.V4Pip0,Rez.Drawables.V4Pip1,Rez.Drawables.V4Pip2,Rez.Drawables.V4Pip3,Rez.Drawables.V4Pip4,Rez.Drawables.V4Pip5],
            [Rez.Drawables.V4Nimble0,Rez.Drawables.V4Nimble1,Rez.Drawables.V4Nimble2,Rez.Drawables.V4Nimble3,Rez.Drawables.V4Nimble4,Rez.Drawables.V4Nimble5],
            [Rez.Drawables.V4Grove30,Rez.Drawables.V4Grove31,Rez.Drawables.V4Grove32,Rez.Drawables.V4Grove33,Rez.Drawables.V4Grove34,Rez.Drawables.V4Grove35],
            [Rez.Drawables.V4Grove40,Rez.Drawables.V4Grove41,Rez.Drawables.V4Grove42,Rez.Drawables.V4Grove43,Rez.Drawables.V4Grove44,Rez.Drawables.V4Grove45],
            [Rez.Drawables.V4Grove50,Rez.Drawables.V4Grove51,Rez.Drawables.V4Grove52,Rez.Drawables.V4Grove53,Rez.Drawables.V4Grove54,Rez.Drawables.V4Grove55],
            [Rez.Drawables.V4Ember30,Rez.Drawables.V4Ember31,Rez.Drawables.V4Ember32,Rez.Drawables.V4Ember33,Rez.Drawables.V4Ember34,Rez.Drawables.V4Ember35],
            [Rez.Drawables.V4Ember40,Rez.Drawables.V4Ember41,Rez.Drawables.V4Ember42,Rez.Drawables.V4Ember43,Rez.Drawables.V4Ember44,Rez.Drawables.V4Ember45],
            [Rez.Drawables.V4Ember50,Rez.Drawables.V4Ember51,Rez.Drawables.V4Ember52,Rez.Drawables.V4Ember53,Rez.Drawables.V4Ember54,Rez.Drawables.V4Ember55],
            [Rez.Drawables.V4Tide30,Rez.Drawables.V4Tide31,Rez.Drawables.V4Tide32,Rez.Drawables.V4Tide33,Rez.Drawables.V4Tide34,Rez.Drawables.V4Tide35],
            [Rez.Drawables.V4Tide40,Rez.Drawables.V4Tide41,Rez.Drawables.V4Tide42,Rez.Drawables.V4Tide43,Rez.Drawables.V4Tide44,Rez.Drawables.V4Tide45],
            [Rez.Drawables.V4Tide50,Rez.Drawables.V4Tide51,Rez.Drawables.V4Tide52,Rez.Drawables.V4Tide53,Rez.Drawables.V4Tide54,Rez.Drawables.V4Tide55],
            [Rez.Drawables.V4Wisp30,Rez.Drawables.V4Wisp31,Rez.Drawables.V4Wisp32,Rez.Drawables.V4Wisp33,Rez.Drawables.V4Wisp34,Rez.Drawables.V4Wisp35],
            [Rez.Drawables.V4Wisp40,Rez.Drawables.V4Wisp41,Rez.Drawables.V4Wisp42,Rez.Drawables.V4Wisp43,Rez.Drawables.V4Wisp44,Rez.Drawables.V4Wisp45],
            [Rez.Drawables.V4Wisp50,Rez.Drawables.V4Wisp51,Rez.Drawables.V4Wisp52,Rez.Drawables.V4Wisp53,Rez.Drawables.V4Wisp54,Rez.Drawables.V4Wisp55]];
        var selected=ids[index(stage,family)];var result=[];
        for(var i=0;i<6;i++){result.add(WatchUi.loadResource(selected[i]));}return result;
    }
}
