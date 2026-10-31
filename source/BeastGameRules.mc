// Deterministic mini-game calculations. Timing units are existing 250ms ticks.
// No input/rendering, clock, storage, reward claims or session ownership.
// Foreground only: game rounds/loot are never resolved by background callbacks.
module BeastGameRules {
    function nextSeed(seed){return (seed*17+11)%65521;}
    function trailSeed(seed,route,node,choice){return (seed+route*97+node*41+choice*211)%65521;}
    function period(easy,round){return easy?[24,20,16][round]:[16,12,9][round];}
    function tempo(easy){return easy?8:6;}
    function cueGap(){return 1;}
    function jumpDuration(easy,round){return easy?7:[7,6,5][round];}
    function displayedMove(sequence,phase,elapsed,easy){
        var duration=tempo(easy);var cycle=duration+cueGap();
        if(phase!=1 || sequence.size()==0 || elapsed%cycle>=duration){return -1;}
        var index=(elapsed/cycle).toNumber();
        return sequence[index<sequence.size()?index:sequence.size()-1];
    }
    function treasureItem(seed,risk,finds,route,discoveryMask){
        var pools=[[0,1,2,7],[0,5,1,6],[0,3,2,7],[0,4,6,5]];
        var mixed=(seed*17+risk*31+finds*13)%65521;
        var pool=pools[route];var item=pool[mixed%pool.size()];
        if(finds>=2){for(var i=0;i<8;i++){
            var candidate=(mixed+i)%8;if((discoveryMask&(1<<candidate))==0){item=candidate;break;}}}
        return item;
    }
}
