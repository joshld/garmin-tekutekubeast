using Toybox.Test;
using Toybox.Application;
(:test)
class UpdateFake extends BeastUpdates {
    var requests=0;var broken=false;
    function initialize(storage,version,channel){BeastUpdates.initialize(storage,version,channel,null);}
    function request(){requests++;if(broken){throw new Toybox.Lang.Exception("offline");}}
}
(:test)
class UpdateRealStore extends BeastStore {
    function initialize(){BeastStore.initialize();}
    function read(key){return BeastStore.read("upd.qa."+key);}
    function write(key,value){return BeastStore.write("upd.qa."+key,value);}
}
(:test)
module UpdateTestSupport {
    function store(){var s=new BeastStore();s.memory={};return s;}
    function ready(storage){var u=new UpdateFake(storage,"0.7.0","stable");u.start(200000l);u.received(200,{"stable"=>"0.7.1","beta"=>"0.8.0-beta.1"});return u;}
}
(:test)
function updateSemverNumericAndPrereleaseTest(logger){
    var pairs=[["0.10.0","0.9.9"],["2.0.0","1.99.9"],["1.0.10","1.0.9"],["1.0.0","1.0.0-rc.1"],["1.0.0-beta.11","1.0.0-beta.2"],["1.0.0-beta","1.0.0-alpha"],["1.0.0-alpha.beta","1.0.0-alpha.1"]];
    for(var i=0;i<pairs.size();i++){Test.assertEqual(BeastUpdateRules.compare(pairs[i][0],pairs[i][1]),1);Test.assertEqual(BeastUpdateRules.compare(pairs[i][1],pairs[i][0]),-1);}
    Test.assertEqual(BeastUpdateRules.compare("1.0.0+build.1","1.0.0+build.2"),0);
    Test.assertEqual(BeastUpdateRules.compare("0.7.0","0.7.0"),0);
    var bad=[null,42,"","0.7","v0.7.0","01.2.3","1.2.3.4","1.2.3-","1.2.3-a..b","1.2.3-01","1.2.3+a+b","1.2.3 bad","9999999999.1.1"];
    for(var b=0;b<bad.size();b++){Test.assert(BeastUpdateRules.parse(bad[b])==null);}return true;
}
(:test)
function updateChannelAndResponseValidationTest(logger){
    var manifest={"stable"=>"0.7.1","beta"=>"0.8.0-beta.1"};
    var owner=new UpdateFake(UpdateTestSupport.store(),"0.7.0",BeastBuild.CHANNEL);owner.start(200000l);owner.received(200,manifest);Test.assertEqual(owner.offer(200000l),"0.8.0-beta.1");
    var publicBuild=new UpdateFake(UpdateTestSupport.store(),"0.7.0","stable");publicBuild.start(200000l);publicBuild.received(200,manifest);Test.assertEqual(publicBuild.offer(200000l),"0.7.1");
    Test.assertEqual(BeastUpdateRules.release(manifest,"stable"),"0.7.1");Test.assertEqual(BeastUpdateRules.release(manifest,"beta"),"0.8.0-beta.1");
    var bad=[null,[],"{}",{}, {"stable"=>"0.7.1"}, {"stable"=>false,"beta"=>"0.8.0"},{"stable"=>"0.7.1","beta"=>"wrong"}];
    for(var i=0;i<bad.size();i++){Test.assert(BeastUpdateRules.release(bad[i],"stable")==null);}
    Test.assert(BeastUpdateRules.release(manifest,"other")==null);Test.assert(BeastUpdateRules.parse(BeastBuild.VERSION)!=null);Test.assertEqual(BeastBuild.CHANNEL,"beta");return true;
}
(:test)
function updateCurrentNewerAndDefaultChoiceTest(logger){
    var s=UpdateTestSupport.store();var u=UpdateTestSupport.ready(s);Test.assertEqual(u.offer(200001l),"0.7.1");Test.assert(u.offer(200002l)==null);
    var prompt=new BeastUpdatePrompt("0.7.1");Test.assertEqual(prompt.choice,0);prompt.move(1);Test.assertEqual(prompt.choice,1);prompt.move(-1);Test.assertEqual(prompt.choice,0);
    var versions=["0.7.1","0.8.0","1.0.0"];for(var n=0;n<versions.size();n++){var current=new UpdateFake(s,versions[n],"stable");Test.assert(current.offer(200001l)==null);}return true;
}
(:test)
function updateAttemptThrottleOfflineAndRollbackTest(logger){
    var s=UpdateTestSupport.store();var u=new UpdateFake(s,"0.7.0","stable");u.broken=true;u.start(200000l);u.start(300000l);Test.assertEqual(u.requests,1);Test.assert(!u.pending);
    var again=new UpdateFake(s,"0.7.0","stable");again.start(286399l);Test.assertEqual(again.requests,0);again=new UpdateFake(s,"0.7.0","stable");again.start(199000l);Test.assertEqual(again.requests,0);
    again=new UpdateFake(s,"0.7.0","stable");again.start(286400l);Test.assertEqual(again.requests,1);Test.assertEqual(s.writes,2);return true;
}
(:test)
function updateLaterExact24hAndRestartTest(logger){
    var s=UpdateTestSupport.store();var u=UpdateTestSupport.ready(s);var version=u.offer(200001l);u.dismiss(version,0,200001l);Test.assert(u.offer(400000l)==null);
    var reopened=new UpdateFake(s,"0.7.0","stable");Test.assert(reopened.offer(286400l)==null);
    reopened=new UpdateFake(s,"0.7.0","stable");Test.assertEqual(reopened.offer(286401l),"0.7.1");return true;
}
(:test)
function updateIgnoreVersionAndNewReleaseTest(logger){
    var s=UpdateTestSupport.store();var u=UpdateTestSupport.ready(s);u.dismiss(u.offer(200001l),1,200001l);
    var reopened=new UpdateFake(s,"0.7.0","stable");Test.assert(reopened.offer(900000l)==null);
    reopened.start(900000l);reopened.received(200,{"stable"=>"0.7.2","beta"=>"0.8.0"});Test.assertEqual(reopened.offer(900001l),"0.7.2");
    reopened.dismiss("0.7.2",0,900001l);
    var next=new UpdateFake(s,"0.7.0","stable");next.start(1000000l);next.received(200,{"stable"=>"0.7.3","beta"=>"0.8.0"});Test.assertEqual(next.offer(1000001l),"0.7.3");return true;
}
(:test)
function updateErrorsStaleCallbacksAndWriteLimitsTest(logger){
    var s=UpdateTestSupport.store();var u=new UpdateFake(s,"0.7.0","stable");u.received(200,{"stable"=>"9.0.0","beta"=>"9.0.0"});Test.assert(u.offer(200000l)==null);
    u.start(200000l);u.received(-2,null);u.received(200,{"stable"=>"9.0.0","beta"=>"9.0.0"});Test.assert(u.offer(200000l)==null);Test.assertEqual(s.writes,1);
    var next=new UpdateFake(s,"0.7.0","stable");next.start(300000l);next.received(200,{"stable"=>"0.7.0","beta"=>"0.8.0"});Test.assert(next.offer(300000l)==null);
    next=new UpdateFake(s,"0.7.0","stable");next.start(400000l);next.received(200,{"stable"=>"bad","beta"=>"0.8.0"});Test.assert(next.offer(400000l)==null);return true;
}
(:test)
function updateRealStoragePersistenceAndPetSafetyTest(logger){
    var s=new UpdateRealStore();s.write("updates.v1",BeastUpdateRules.clean(null));var u=UpdateTestSupport.ready(s);u.dismiss("0.7.1",1,200000l);
    var reopened=new UpdateFake(new UpdateRealStore(),"0.7.0","stable");Test.assertEqual(reopened.state["ignored"],"0.7.1");Test.assert(reopened.offer(500000l)==null);
    var pet=TestSupport.fixture();var saved=pet.store.copy(pet.data);var writes=pet.store.writes;
    var separate=UpdateTestSupport.ready(pet.store);separate.dismiss("0.7.1",0,200001l);
    Test.assert(TestSupport.same(saved,pet.data));Test.assertEqual(pet.store.writes,writes+3);Test.assert(!pet.data.hasKey("updates.v1"));return true;
}
(:test)
function updateIdlePetOnlyAndButtonInputTest(logger){
    var app=Application.getApp();var oldGame=app.gameView;var oldActive=app.activeView;
    var v=new TekuTekuBeastView();v.beast=TestSupport.fixture();v.updates=UpdateTestSupport.ready(UpdateTestSupport.store());v.updateVisible=true;
    app.gameView=v;app.activeView=v;v.menu="Play";v.considerUpdate();Test.assert(v.updatePrompt==null);
    v.menu=null;v.page=1;v.considerUpdate();Test.assert(v.updatePrompt==null);v.page=0;v.notice="EVOLVED";v.considerUpdate();Test.assert(v.updatePrompt==null);v.notice=null;
    app.activeView=new BeastGameView(v.beast,0);v.considerUpdate();Test.assert(v.updatePrompt==null);
    app.activeView=new BeastBattleView(v.beast);v.considerUpdate();Test.assert(v.updatePrompt==null);
    app.activeView=v;v.updateVisible=false;v.considerUpdate();Test.assert(v.updatePrompt==null);v.updateVisible=true;
    v.considerUpdate();Test.assert(v.updatePrompt!=null);Test.assertEqual(v.updatePrompt.choice,0);v.switchPage(1);Test.assertEqual(v.updatePrompt.choice,1);v.selectAction();Test.assert(v.updatePrompt==null);Test.assertEqual(v.updates.state["ignored"],"0.7.1");
    v.considerUpdate();Test.assert(v.updatePrompt==null);app.gameView=oldGame;app.activeView=oldActive;return true;
}

(:test)
class UpdateFailingStore extends BeastStore {
    function initialize(){BeastStore.initialize();memory={};}
    function write(key,value){throw new Toybox.Lang.InvalidValueException("QA storage unavailable");}
}
(:test)
class UpdateUnreadableStore extends BeastStore {
    function initialize(){BeastStore.initialize();memory={};}
    function read(key){throw new Toybox.Lang.InvalidValueException("QA read unavailable");}
}
(:test)
function updateUnchangedWritesAndFailedThrottleStorageTest(logger){
    var s=UpdateTestSupport.store();var u=UpdateTestSupport.ready(s);Test.assertEqual(s.writes,2);
    var next=new UpdateFake(s,"0.7.0","stable");next.start(300000l);next.received(200,{"stable"=>"0.7.1","beta"=>"0.8.0-beta.1"});Test.assertEqual(s.writes,3);
    next.offer(300000l);Test.assert(!next.review);Test.assert(next.offer(900000l)==null);Test.assertEqual(s.writes,3);
    var failed=new UpdateFake(new UpdateFailingStore(),"0.7.0","stable");failed.start(200000l);Test.assertEqual(failed.requests,0);
    var unreadable=new UpdateFake(new UpdateUnreadableStore(),"0.7.0","stable");unreadable.start(200000l);Test.assertEqual(unreadable.requests,0);Test.assertEqual(unreadable.store.writes,0);
    var invalid=new UpdateFake(s,"0.7.0","stable");invalid.start(0l);Test.assertEqual(invalid.requests,0);
    var corrupt=new BeastStore();corrupt.memory={"updates.v1"=>{"checked"=>"bad","ignored"=>[],"remindAt"=>-1}};
    var clean=new UpdateFake(corrupt,"0.7.0","stable");Test.assertEqual(clean.state["checked"],0l);Test.assertEqual(clean.state["ignored"],"");return true;
}
