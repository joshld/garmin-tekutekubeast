// Stable protocol roster. Never reorder forms/slots: ID = form * 4 + slot.
// Roles are implementation details; player-facing controls always use names.
module BeastBattleMoves {
    function form(stage,family,rare){
        if(stage<=0){return -1;}if(stage==1){return 0;}if(stage==2){return 1;}
        if(family<1 || family>4){family=1;}
        return 2+(family-1)*4+(stage>=5 && rare==1?3:(stage>=5?2:stage-3));
    }
    function names(form){return BeastBattleData.names(form);}
    function id(form,slot){return form*4+slot;}
    function species(form){return BeastBattleData.species(form);}
    function name(id){return names((id/4).toNumber())[id%4];}
    function role(id){return id%4;}
}
