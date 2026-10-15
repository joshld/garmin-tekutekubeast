using Toybox.WatchUi;
// Generated asset catalog: cache only the current creature's six frames.
class BeastArt {
    function initialize() {}
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
