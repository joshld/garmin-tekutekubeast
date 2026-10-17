using Toybox.WatchUi;

// Representative profiles run all 983 scenes. Other candidates still exercise
// every species, menu row, care/detail page, game state and adventure choice,
// plus all 16 theme/palette combinations. Avoid repeating the representative's
// exhaustive 270 movement/256 world permutations for every equivalent SKU.
class CompatibilityLayoutAudit extends ArtLayoutAuditView {
    var originalCount=0;var basicCount=0;
    function initialize(){
        ArtLayoutAuditView.initialize();originalCount=sceneCount;
        basicCount=originalCount-270-25-256;sceneCount=basicCount+25+16;
    }
    function sceneAt(index){
        if(index<basicCount){return ArtLayoutAuditView.sceneAt(index);}
        index-=basicCount;
        if(index<25){return ArtLayoutAuditView.sceneAt(basicCount+270+index);}
        index-=25;
        return ArtLayoutAuditView.sceneAt(originalCount-256+(index/4).toNumber()*64+(index%4)*16);
    }
}
(:background,:glance)
class MatrixApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){var view=new CompatibilityLayoutAudit();view.exitWhenDone=true;return [view,new TekuTekuBeastInput(view)];}
}
