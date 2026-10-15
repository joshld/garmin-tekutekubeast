using Toybox.WatchUi;
// Same production entry-point/glance implementation; isolated QA application ID.
(:background, :glance)
class MatrixApp extends TekuTekuBeastApp {
    function initialize(){TekuTekuBeastApp.initialize();}
    function getInitialView(){
        var view=new ArtLayoutAuditView();view.exitWhenDone=true;
        return [view,new TekuTekuBeastInput(view)];
    }
}
