//cdnjs.cloudflare.com/ajax/libs/snap.svg/0.4.1/snap.svg-min.js
//cdnjs.cloudflare.com/ajax/libs/gsap/1.19.0/TweenMax.min.js
&G_APP_FILES.lib/ghosts#MIN#.js

function makeGhost() {
    if (wmgVisible) {
        stageManager.addGhost();
    }
    setTimeout(makeGhost, Math.random() * 500);
}

let wmgVisible = true; stageManager = new StageManager(Snap('svg'));

stageManager.init();
makeGhost();
