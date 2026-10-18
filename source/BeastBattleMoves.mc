// Stable protocol roster. Never reorder forms/slots: ID = form * 4 + slot.
// Roles are implementation details; player-facing controls always use names.
module BeastBattleMoves {
    function form(stage,family,rare){
        if(stage<=0){return -1;}if(stage==1){return 0;}if(stage==2){return 1;}
        if(family<1 || family>4){family=1;}
        return 2+(family-1)*4+(stage>=5 && rare==1?3:(stage>=5?2:stage-3));
    }
    function names(form){
        if(form<0){return [];}
        switch(form){
            case 0:return ["Tiny Tackle","Curl Up","Happy Chirp","Pip Pop"];
            case 1:return ["Quick Pounce","Swift Dodge","Brave Bounce","Whirlwind Dash"];
            case 2:return ["Leaf Flick","Bark Guard","Growing Spirit","Root Snare"];
            case 3:return ["Thorn Swipe","Bramble Wall","Forest Cry","Thorn Barrage"];
            case 4:return ["Vine Lash","Ancient Bark","Nature's Blessing","Verdant Fury"];
            case 5:return ["Luminous Vine","Sacred Grove","Heartbloom","Aurora Roots"];
            case 6:return ["Ember Pop","Cinder Shield","Burning Courage","Blazing Pounce"];
            case 7:return ["Flame Claw","Heat Veil","Fireheart Roar","Inferno Claw"];
            case 8:return ["Solar Slash","Sunfire Ward","Radiant Roar","Solar Inferno"];
            case 9:return ["Phoenix Talon","Ashen Guard","Rekindle","Phoenix Rebirth"];
            case 10:return ["Bubble Burst","Ripple Guard","Flowing Spirit","Tidal Spin"];
            case 11:return ["Aqua Strike","Wave Screen","Ocean Pulse","Riptide Crash"];
            case 12:return ["Abyss Bite","Deep Guard","Tidal Majesty","Abyssal Surge"];
            case 13:return ["Moonlit Torrent","Silver Mist","Tranquil Waters","Lunar Tidalwave"];
            case 14:return ["Star Spark","Phantom Veil","Starlight Wish","Phantom Blink"];
            case 15:return ["Moonlash","Dusk Shroud","Night Hymn","Lunar Hex"];
            case 16:return ["Comet Pierce","Astral Veil","Celestial Song","Eclipse Nova"];
            case 17:return ["Void Lance","Eclipse Cloak","Cosmic Harmony","Eternal Eclipse"];
        }
        return names(0);
    }
    function id(form,slot){return form*4+slot;}
    function species(form){return ["Pip","Nimble","Mossbit","Thornbuck","Verdant Elder","Lumenhart",
        "Cindercub","Pyrolynx","Solflare","Ashen Phoenix","Puddlefin","Currentail","Leviathan",
        "Moonwater Kirin","Flicklet","Nocturne","Starweaver","Eclipse Eidolon"][form];}
    function name(id){return names((id/4).toNumber())[id%4];}
    function role(id){return id%4;}
}
