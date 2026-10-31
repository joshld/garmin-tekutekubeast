using Toybox.Graphics;
// Two choices only; existing fonts/highlight style, no timer or resources.
class BeastUpdatePrompt {
    var version;var choice=0;var font=Graphics.FONT_XTINY;
    function initialize(available){version=available;}
    function move(delta){choice=(choice+delta+2)%2;}
    function lines(dc,text,width){
        var result=[];var start=0;var gap=-1;var cursor=0;
        while(cursor<text.length()){
            if(text.substring(cursor,cursor+1).equals(" ")){gap=cursor;}
            if(dc.getTextWidthInPixels(text.substring(start,cursor+1),font)>width && cursor>start){
                var end=gap>=start?gap:cursor;result.add(text.substring(start,end));start=gap>=start?gap+1:cursor;cursor=start;gap=-1;
            }else{cursor++;}
        }if(start<text.length()){result.add(text.substring(start,text.length()));}return result;
    }
    function draw(view,dc){
        dc.setColor(view.BG,view.BG);dc.clear();view.sceneInk=view.INK;
        view.label(dc,view.y(dc,0.20),"Update available!",font);
        var top=view.y(dc,0.32);var message=lines(dc,"TekuTekuBeast v"+version+" is available!",dc.getWidth()*0.78);
        for(var i=0;i<message.size();i++){view.label(dc,top+i*(dc.getFontHeight(font)+1),message[i],font);}
        var options=["Remind me later","Don't remind me"];
        for(var n=0;n<2;n++){
            var y=view.y(dc,n==0?0.62:0.73);var w=dc.getTextWidthInPixels(options[n],font);
            if(n==choice){dc.setColor(view.LIGHT,Graphics.COLOR_TRANSPARENT);dc.fillRoundedRectangle(dc.getWidth()/2-w/2-3,y-1,w+6,dc.getFontHeight(font)+2,3);}
            view.label(dc,y,options[n],font);
        }
    }
}
