using Toybox.Test;

(:test)
module FamilyAffinityTestSupport {
    function data(){
        var s=TestSupport.fixture();
        s.data["affinity"]=[0,0,0,0];s.data["affinityToday"]=[0,0,0,0];
        s.data["affinityDay"]=100;s.data["temperament"]=1;
        return s;
    }
    function ties(points,expected){
        var s=data();s.data["affinity"]=points;s.data["petSerial"]=0;
        var counts=[0,0,0,0];
        for(var epoch=1792108800l;epoch<1792108812l;epoch++){
            s.data["birthEpoch"]=epoch;counts[BeastAffinity.choose(s.data)-1]++;
        }
        Test.assert(TestSupport.same(counts,expected));
    }
}

(:test)
function affinityTemperamentAndHintsTest(logger){
    var counts=[0,0,0,0];var s=FamilyAffinityTestSupport.data();
    for(var i=0;i<32;i++){
        var epoch=1792108800l+i;var innate=BeastAffinity.temperament(epoch,7);
        Test.assert(innate>=1 && innate<=4);
        Test.assertEqual(innate,BeastAffinity.temperament(epoch,7));counts[innate-1]++;
    }
    for(var i=0;i<4;i++){
        Test.assert(counts[i]>0);s.data["temperament"]=i+1;
        Test.assertEqual(BeastAffinity.choose(s.data),i+1);
    }
    Test.assertEqual(BeastAffinity.hint(s.data),"Growing curious");
    Test.assert(BeastAffinity.temperament(-1,-1)>=1);return true;
}

(:test)
function affinityFairPartialAndFullTiesTest(logger){
    // Temperament 1 contributes two points, cancelled here to make exact ties.
    FamilyAffinityTestSupport.ties([3,0,0,5],[6,0,0,6]);
    FamilyAffinityTestSupport.ties([3,5,5,0],[4,4,4,0]);
    FamilyAffinityTestSupport.ties([0,2,2,2],[3,3,3,3]);
    var s=FamilyAffinityTestSupport.data();s.data["affinity"]=[3,0,0,5];
    s.data["birthEpoch"]=1792108800l;s.data["petSerial"]=0;
    var first=BeastAffinity.choose(s.data);s.data["petSerial"]=1;
    Test.assert(first!=BeastAffinity.choose(s.data));return true;
}

(:test)
function affinityUniqueMaximumNeutralityAndPurityTest(logger){
    var s=FamilyAffinityTestSupport.data();s.data["affinity"]=[1,2,20,3];
    var before=s.store.copy(s.data);
    Test.assertEqual(BeastAffinity.choose(s.data),3);
    Test.assert(TestSupport.same(before,s.data));
    s.data["personality"]=[999,0,0,0];s.data["counts"][0]=40000;
    s.data["xp"]=900000;s.data["careGrowth"]=999;s.data["activityBonus"]=999;
    Test.assertEqual(BeastAffinity.choose(s.data),3);return true;
}

(:test)
function affinityDailyCapAndRollbackTest(logger){
    var s=FamilyAffinityTestSupport.data();var d=s.data;
    Test.assertEqual(BeastAffinity.credit(d,2,4,100),4);
    Test.assertEqual(BeastAffinity.credit(d,2,4,100),2);
    Test.assertEqual(BeastAffinity.credit(d,2,1,100),0);
    Test.assertEqual(BeastAffinity.credit(d,3,6,100),6);
    Test.assertEqual(BeastAffinity.credit(d,2,6,99),0);
    Test.assertEqual(BeastAffinity.credit(d,1,6,99),0);
    Test.assertEqual(BeastAffinity.credit(d,2,3,101),3);
    Test.assertEqual(d["affinity"][1],9);Test.assertEqual(d["affinityToday"][2],0);
    Test.assertEqual(BeastAffinity.credit(d,0,2,101),0);
    Test.assertEqual(BeastAffinity.credit(d,5,2,101),0);
    Test.assertEqual(BeastAffinity.credit(d,1,0,101),0);
    Test.assertEqual(BeastAffinity.credit(d,1,-2,101),0);return true;
}

(:test)
function affinityPersistenceAndRepeatedCreditTest(logger){
    var s=FamilyAffinityTestSupport.data();
    BeastAffinity.credit(s.data,4,6,100);s.commit();
    var winner=BeastAffinity.choose(s.data);var saved=s.store.copy(s.data);
    s.data=null;s.start();
    Test.assert(TestSupport.same(s.data["affinity"],saved["affinity"]));
    Test.assert(TestSupport.same(s.data["affinityToday"],saved["affinityToday"]));
    Test.assertEqual(s.data["temperament"],saved["temperament"]);
    Test.assertEqual(s.data["affinityDay"],saved["affinityDay"]);
    Test.assertEqual(BeastAffinity.choose(s.data),winner);
    Test.assertEqual(BeastAffinity.credit(s.data,4,6,100),0);return true;
}
(:test)
module FamilyAffinityProductionSupport {
    function care(s){
        s.pat();s.pat();s.pat();s.feedFood(true);s.feedFood(true);
        if(s.number("poop")>0){s.clean();}
        s.rest();s.wakeUp();
    }
    function optional(s,family){
        var toy=family==2?1:(family==3?3:(family==4?6:-1));
        if(toy>=0){s.useItem(toy);}
        for(var game=0;game<4;game++){
            var kind=family==2?0:(family==4?1:2);
            var session=s.beginSession(kind);Test.assert(session!=null);
            if(kind==2){session["route"]=family-1;session["finds"]=1;}
            s.completeSession(session,true);
            var before=s.store.copy(s.data["affinity"]);
            Test.assert(s.completeSession(session,true).equals("ALREADY SAVED"));
            Test.assert(TestSupport.same(before,s.data["affinity"]));
        }
    }
    function week(family,steps,careFirst){
        var s=TestSupport.fixture();s.data["sleepMode"]=2;
        // The single permanent toy is a normal inventory item, not a test credit.
        s.data["items"][1]=1;s.data["items"][3]=1;s.data["items"][6]=1;
        var start=s.testNow;
        for(var day=0;day<7;day++){
            s.testNow=start+day*86400+36000;s.tick();s.observe(s.today(),steps);
            if(careFirst){care(s);optional(s,family);}else{optional(s,family);care(s);}
            s.commit();s.data=null;s.start();
        }
        s.testNow=start+7*86400+36000;s.tick();
        Test.assertEqual(s.family(),family);return s;
    }
}

(:test)
function affinityProductionSevenDayPathsAndActivityTest(logger){
    for(var family=1;family<=4;family++){
        var baseline=FamilyAffinityProductionSupport.week(family,0,true);
        Test.assert(baseline.data["affinity"][family-1]>=42);
        for(var activity=0;activity<3;activity++){
            var steps=[0,6000,40000][activity];
            for(var order=0;order<2;order++){
                var s=FamilyAffinityProductionSupport.week(family,steps,order==0);
                Test.assert(TestSupport.same(baseline.data["affinity"],s.data["affinity"]));
                Test.assertEqual(s.family(),family);
                Test.assertEqual(s.xp(),(steps*7).toLong());
            }
        }
    }
    return true;
}

(:test)
function affinityLegacyAdditiveMigrationAndAdultLockTest(logger){
    for(var adult=0;adult<2;adult++){
        var s=TestSupport.fixture();s.observe(s.today(),5500);
        s.data["friendship"]=61;s.data["snacks"]=4;s.data["items"][3]=2;
        s.data["collection"]=7;s.data["personality"]=[0,0,50,0];
        s.data["careGrowth"]=200l;s.data["stageFloor"]=adult==1?3:2;
        s.data["family"]=0;
        var keys=["affinity","affinityToday","affinityDay","temperament"];
        for(var i=0;i<keys.size();i++){s.data.remove(keys[i]);}
        var expected=BeastProgression.chooseFamily(s.data);
        var before=s.store.copy(s.data);s.store.write("v4",before);
        s.data=null;s.start();
        // Migration is additive; freeze the old adult choice, never a new branch.
        var oldKeys=before.keys();
        for(var i=0;i<oldKeys.size();i++){
            var key=oldKeys[i];if(key.equals("family") && adult==1){continue;}
            Test.assert(TestSupport.same(s.data[key],before[key]));
        }
        Test.assertEqual(s.number("family"),adult==1?expected:0);
        Test.assert(TestSupport.same(s.data["affinity"],[0,0,0,0]));
        Test.assertEqual(s.number("temperament"),BeastAffinity.temperament(s.number("birthEpoch"),s.number("petSerial")));
        if(adult==1){
            var other=expected%4+1;BeastAffinity.credit(s.data,other,6,s.today());
            Test.assertEqual(s.family(),expected);s.commit();s.data=null;s.start();
            Test.assertEqual(s.family(),expected);
        }
    }
    return true;
}
