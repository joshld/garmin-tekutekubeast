// Foreground boundary: detached combat snapshot; never opens the solo journal.
module BeastFriendModel {
    function snapshot(beast){
        beast.start();var saved=beast.battleData;
        if(saved==null){saved=beast.store.read("battle.v1");}
        var xp=0;var mastery=null;
        if(saved!=null && saved.hasKey("xp")){xp=saved["xp"];if(saved.hasKey("mastery")){mastery=saved["mastery"];}}
        var family=beast.dev?beast.family():beast.number("family");
        if(family==0 && beast.stage()>=3){family=BeastProgression.chooseFamily(beast.data);}
        return BeastBattleRules.fighter(beast.stage(),family,beast.number("rare"),beast.friendship(),beast.data["personality"],xp,mastery);
    }
    function serial(beast){
        var n=beast.store.read("friend.serial.v1");if(n==null){n=0;}
        if(!BeastBattleRules.integer(n,0,16777214)){return 0;}
        n=n.toNumber()+1;beast.store.write("friend.serial.v1",n);return n;
    }
}
