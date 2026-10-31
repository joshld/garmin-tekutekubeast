using Toybox.Test;

(:test)
module CareTestSupport {
    function pet(mode){var s=TestSupport.fixture();s.data["sleepMode"]=2;s.setCareDifficulty(mode);return s;}
    function reopen(s){var r=new TekuTekuBeastState();r.store=s.store;r.skipWatch=true;r.testNow=s.now();r.start();return r;}
    function sum(d){var n=0;for(var i=1;i<8;i+=2){n+=d["digestion"][i];}return n;}
}
(:test)
function careDifficultyDecayAndAbsenceTest(logger){
    for(var mode=0;mode<3;mode++){
        for(var period=0;period<4;period++){
            var days=[1,3,7,14][period];var s=CareTestSupport.pet(mode);
            s.data["fullness"]=100;s.data["happiness"]=100;var xp=s.xp();var at=s.now();
            s.testNow+=days*86400;s.tick();var charged=s.min(3,days);
            Test.assertEqual(s.number("fullness"),s.max(10,100-charged*[6,20,30][mode]));
            Test.assertEqual(s.number("happiness"),s.max(15,100-charged*[4,12,20][mode]));
            Test.assertEqual(s.xp(),xp);Test.assertEqual(s.number("careAt"),s.now());
            s.commit();var saved=s.store.copy(s.data);s.tick();s.commit();Test.assert(s.store.same(saved,s.data));
            var r=CareTestSupport.reopen(s);r.tick();Test.assert(s.store.same(saved,r.data));
            s.testNow=at;s.tick();Test.assertEqual(s.number("fullness"),saved["fullness"]);
            Test.assertEqual(s.number("careAt"),saved["careAt"]);
        }
    }
    return true;
}
(:test)
function careFractionalSwitchAndProjectionTest(logger){
    var a=CareTestSupport.pet(0);var b=CareTestSupport.pet(0);a.data["fullness"]=100;b.data["fullness"]=100;
    for(var i=0;i<48;i++){a.testNow+=900;a.tick();}
    b.testNow+=43200;b.tick();Test.assertEqual(a.number("fullness"),97);Test.assertEqual(a.number("fullness"),b.number("fullness"));
    a.setCareDifficulty(2);a.testNow+=43200;
    var projected=BeastCareRules.projected(a.data,a.now(),true);a.tick();Test.assertEqual(a.number("fullness"),82);Test.assertEqual(projected,82);
    a.commit();var r=CareTestSupport.reopen(a);Test.assertEqual(r.number("careDifficulty"),2);
    Test.assertEqual(r.number("foodRemainder"),a.number("foodRemainder"));
    var growth=r.growth();r.setCareDifficulty(0);Test.assertEqual(r.growth(),growth);return true;
}
(:test)
function careMigrationAndPetSafetyTest(logger){
    var s=CareTestSupport.pet(2);s.data["family"]=3;s.data["stageFloor"]=3;s.data["xp"]=120000l;
    s.data["friendship"]=77;s.data["poop"]=3;s.data["poopSlots"]=21;s.data["cleanliness"]=55;
    var keys=["careDifficulty","careAt","foodRemainder","joyRemainder","careStepDay","careStepUnits","digestion","digestRemainder","digestDay","digestWaste"];
    for(var i=0;i<keys.size();i++){s.data.remove(keys[i]);}
    var before=s.store.copy(s.data);s.store.write("v4",before);var r=CareTestSupport.reopen(s);
    var oldKeys=before.keys();for(var i=0;i<oldKeys.size();i++){Test.assert(s.store.same(before[oldKeys[i]],r.data[oldKeys[i]]));}
    Test.assertEqual(r.number("careDifficulty"),1);Test.assertEqual(r.poopMask(),21);Test.assertEqual(r.family(),3);
    r.commit();var writes=r.store.writes;r.commit();Test.assertEqual(r.store.writes,writes);
    var dev=r.enableDev();dev.setCareDifficulty(2);dev.testNow+=86400;dev.tick();dev.clean();
    Test.assert(s.store.same(r.store.read("v4"),r.data));return true;
}
(:test)
function careActivityCapsAndIdempotenceTest(logger){
    for(var mode=0;mode<3;mode++){
        for(var sample=0;sample<4;sample++){
            var s=CareTestSupport.pet(mode);var steps=[0,5000,10000,40000][sample];var units=s.min(5,steps/2000);
            s.observe(s.today(),steps);var cap=[3,5,8][mode];var each=mode==2?2:1;
            Test.assertEqual(s.number("fullness"),75-s.min(cap,units*each));
            Test.assertEqual(s.number("energy"),80-s.min([2,4,5][mode],units));
            Test.assertEqual(s.number("happiness"),65+units/2);Test.assertEqual(s.xp(),steps.toLong());
            var before=s.store.copy(s.data);s.observe(s.today(),steps);s.observe(s.today(),steps/2);
            Test.assert(s.store.same(before,s.data));s.commit();var r=CareTestSupport.reopen(s);
            r.observe(r.today(),steps);Test.assert(s.store.same(s.data,r.data));
            r.testNow-=86400;r.observe(r.today(),40000);Test.assertEqual(r.number("fullness"),s.number("fullness"));
        }
    }
    return true;
}
(:test)
function careDigestionDelayMealsSnacksAndCapsTest(logger){
    for(var mode=0;mode<3;mode++){
        var s=CareTestSupport.pet(mode);var at=s.now();s.data["fullness"]=30;
        Test.assert(s.feedFood(true));Test.assertEqual(CareTestSupport.sum(s.data),2);
        s.data["snacks"]=12;Test.assert(s.feedFood(false));Test.assertEqual(CareTestSupport.sum(s.data),3);
        Test.assertEqual(s.number("poop"),0);s.commit();s=CareTestSupport.reopen(s);
        s.testNow=at+BeastCareRules.delay(s.data)-1;s.tick();Test.assertEqual(s.number("poop"),0);
        s.testNow++;s.tick();Test.assertEqual(s.number("poop"),1);Test.assertEqual(s.number("cleanliness"),85);
        Test.assertEqual(CareTestSupport.sum(s.data),0);Test.assert(s.clean());Test.assertEqual(s.number("poop"),0);
        for(var i=0;i<12;i++){s.data["fullness"]=30;s.feedFood(false);}
        Test.assert(CareTestSupport.sum(s.data)<=8);s.testNow+=BeastCareRules.delay(s.data);s.tick();
        Test.assert(s.number("digestWaste")<=mode+1);Test.assert(s.number("poop")<=mode);
        var count=s.number("poop");s.tick();Test.assertEqual(s.number("poop"),count);
    }
    return true;
}
(:test)
function careNaturalWasteCleaningAndRollbackTest(logger){
    for(var mode=0;mode<3;mode++){
        var s=CareTestSupport.pet(mode);var at=s.now();s.data["poopDue"]=at+BeastCareRules.interval(s.data);
        s.testNow+=86400;s.tick();Test.assertEqual(s.number("poop"),[1,1,2][mode]);
        s.testNow=at+2*86400;s.tick();Test.assertEqual(s.number("poop"),[2,3,4][mode]);
        s.testNow=at+14*86400;s.tick();Test.assertEqual(s.number("poop"),5);Test.assertEqual(s.poopMask(),31);
        var joy=s.number("happiness");var bond=s.friendship();var growth=s.number("careGrowth");
        for(var n=4;n>=0;n--){Test.assert(s.clean());Test.assertEqual(s.number("poop"),n);Test.assertEqual(s.number("cleanliness"),100-15*n);}
        Test.assertEqual(s.friendship(),bond+3);Test.assertEqual(s.number("careGrowth"),growth+30);Test.assertEqual(s.number("happiness"),joy+3);
        s.tick();Test.assertEqual(s.number("poop"),0);var due=s.number("poopDue");
        s.testNow-=7*86400;s.tick();Test.assertEqual(s.number("poopDue"),due);Test.assertEqual(s.number("poop"),0);
        s.testNow=due;s.tick();Test.assertEqual(s.number("poop"),1);
    }
    return true;
}
(:test)
function careSleepMoodAndEnergyTest(logger){
    var s=CareTestSupport.pet(1);s.data["poop"]=2;s.data["poopSlots"]=3;s.data["cleanliness"]=20;
    Test.assert(s.mood().equals("MESSY"));s.data["fullness"]=20;Test.assert(s.mood().equals("HUNGRY"));
    s.data["energy"]=10;Test.assert(s.mood().equals("SLEEPY"));s.rest();Test.assert(s.mood().equals("RESTING"));
    var before=s.store.copy(s.data);Test.assert(!s.feedFood(true));Test.assert(!s.clean());Test.assert(!s.pat());
    Test.assert(s.store.same(before,s.data));s.testNow+=3599;
    var forecast=BeastSleep.forecastEnergy(s.data,s.now());s.tick();Test.assertEqual(s.number("energy"),forecast);
    s.testNow++;s.tick();Test.assert(s.number("energy")>=38);Test.assert(!s.isSleeping());
    s.data["poop"]=0;s.data["cleanliness"]=20;s.data["fullness"]=75;s.data["energy"]=80;Test.assert(s.mood().equals("MESSY"));return true;
}
(:test)
function careBalanceScenariosTest(logger){
    for(var scenario=0;scenario<6;scenario++){
        var mode=scenario==4?2:1;var s=CareTestSupport.pet(mode);var start=s.now();var minFood=100;var minJoy=100;var actions=0;
        var cadence=scenario==0?172800:(scenario==4?43200:(scenario==5?7*86400:86400));
        for(var elapsed=cadence;elapsed<=14*86400;elapsed+=cadence){
            s.testNow=start+elapsed;s.tick();var steps=scenario==1?5000:(scenario==2?10000:(scenario==3?(elapsed/86400%3==0?40000:20000):0));
            s.observe(s.today(),steps);minFood=s.min(minFood,s.number("fullness"));minJoy=s.min(minJoy,s.number("happiness"));
            for(var meal=0;meal<2;meal++){if(s.feedFood(true)){actions++;}}
            for(var pat=0;pat<3;pat++){if(s.pat()){actions++;}}
            while(s.number("poop")>0){s.clean();actions++;}
            s.commit();s=CareTestSupport.reopen(s);
        }
        logger.debug("CARE_BALANCE scenario="+scenario+" mode="+mode+" minFood="+minFood+" minJoy="+minJoy+" endFood="+s.number("fullness")+" endJoy="+s.number("happiness")+" actions="+actions+" xp="+s.xp());
        Test.assert(s.number("poop")<=5);Test.assert(s.number("fullness")>=10);Test.assert(s.number("happiness")>=15);
    }
    return true;
}

(:test)
class CarePoopDc {
    var color=0;var rectangles=[];
    function initialize(){}
    function getWidth(){return 280;}
    function getHeight(){return 280;}
    function setColor(fg,bg){color=fg;}
    function fillRectangle(x,y,w,h){rectangles.add([x,y,w,h,color]);}
}
(:test)
function careSettingsAndOutlineTest(logger){
    var v=new TekuTekuBeastView();v.beast=CareTestSupport.pet(1);v.openMenu("Settings");
    Test.assert(v.rows[10].equals("Care Difficulty"));v.selection=10;v.selectAction();
    Test.assert(v.menu.equals("Care Difficulty"));Test.assertEqual(v.selection,1);
    v.switchPage(1);v.selectAction();Test.assertEqual(v.beast.number("careDifficulty"),2);
    v.ensureWorld();v.openMenu("Outdoor world");v.openMenu("Care Difficulty");Test.assertEqual(v.selection,2);Test.assert(v.rows[2].equals("High Maintenance"));
    var dc=new CarePoopDc();
    for(var count=0;count<=5;count++){
        dc.rectangles=[];v.beast.data["poop"]=count;v.beast.repairPoop();v.drawPoop(dc);
        Test.assertEqual(dc.rectangles.size(),count*40);
        for(var i=0;i<dc.rectangles.size();i++){
            var r=dc.rectangles[i];Test.assertEqual(r[2],2);Test.assertEqual(r[3],2);
            Test.assert(r[1]>=210 && r[1]+r[3]<=222);
            if(i%40<27){Test.assertEqual(r[4],0x000000);}
        }
    }
    v.animationTicks=0;v.beast.data["poop"]=0;v.beast.data["cleanliness"]=20;
    Test.assert(v.visualState().equals("look"));Test.assert(v.beast.mood().equals("MESSY"));
    v.beast.data["fullness"]=0;v.beast.data["happiness"]=0;v.beast.testNow+=86400;v.beast.tick();
    Test.assertEqual(v.beast.number("fullness"),0);Test.assertEqual(v.beast.number("happiness"),0);Test.assert(BeastSleep.previewMood(v.beast.data,v.beast.now()).equals("HUNGRY"));
    return true;
}

(:test)
class CareDiskStore extends BeastStore {
    var failWrite=false;var failCopy=false;
    function initialize(){BeastStore.initialize();}
    function read(key){var v=BeastStore.read("care.qa."+key);if(key.equals("v4")){canonical=copy(v);}return v;}
    function write(key,value){
        if(failWrite && key.equals("v4")){throw new Toybox.Lang.InvalidValueException("QA write failure");}
        return BeastStore.write("care.qa."+key,value);
    }
    function copy(value){if(failCopy){throw new Toybox.Lang.InvalidValueException("QA snapshot failure");}return BeastStore.copy(value);}
}
(:test)
function careRealStorageSnapshotAndFailureRetryTest(logger){
    var s=CareTestSupport.pet(1);s.store=new CareDiskStore();s.commit();var old=s.number("fullness");
    var raw=s.store.read("v4");raw["fullness"]=0;
    Test.assertEqual(Toybox.Application.Storage.getValue("care.qa.v4")["fullness"],old);
    s.data["fullness"]=old-1;s.store.failWrite=true;var caught=false;
    try{s.commit();}catch(e instanceof Toybox.Lang.InvalidValueException){caught=true;}
    Test.assert(caught);Test.assert(s.store.canonical==null);
    Test.assertEqual(Toybox.Application.Storage.getValue("care.qa.v4")["fullness"],old);
    s.store.failWrite=false;s.commit();Test.assertEqual(s.store.canonical["fullness"],old-1);
    s.data["fullness"]=old-2;s.store.failCopy=true;caught=false;
    try{s.commit();}catch(e instanceof Toybox.Lang.InvalidValueException){caught=true;}
    Test.assert(caught);Test.assert(s.store.canonical==null);
    Test.assertEqual(Toybox.Application.Storage.getValue("care.qa.v4")["fullness"],old-2);
    s.store.failCopy=false;s.commit();var writes=s.store.writes;s.commit();Test.assertEqual(s.store.writes,writes);
    s.data["fullness"]=old-3;Test.assertEqual(s.store.canonical["fullness"],old-2);s.commit();
    Test.assertEqual(Toybox.Application.Storage.getValue("care.qa.v4")["fullness"],old-3);return true;
}
(:test)
function careBackgroundCoreBoundaryTest(logger){
    var core=new BeastStateCore();core.store.memory={};core.skipWatch=true;core.testNow=1792108800l;core.start();
    Test.assert(!(core has :beginSession));Test.assert(!(core has :feedFood));Test.assert(!(core has :enableDev));
    core.observe(core.today(),10000);core.testNow+=86400;core.tick();core.commit();
    Test.assertEqual(core.xp(),10000l);Test.assertEqual(core.number("poop"),1);
    var s=TestSupport.fixture();Test.assert(s has :beginSession);Test.assert(s has :feedFood);Test.assert(s has :enableDev);
    return true;
}
