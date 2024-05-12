function adjustedScore(pStrokes, holePar) {
    let strokes = wmgt.convert.to_number(pStrokes());
    let par = wmgt.convert.to_number(holePar());
    return strokes ? strokes - par : 0;
}

function findCurrentHoleForTwoPlayers(playerE, playerH) {
    let currentHole = 1; // Default to the first hole if no scores are found

    for (let i = 0; i < 18; i++) {
        let eScore = wmgt.convert.to_number(playerE[i]());
        let hScore = wmgt.convert.to_number(playerH[i]());

        if (eScore > 0 && hScore > 0) {
            // If both players have a score, the current hole should be the next one
            currentHole = i + 2;
        } else if (eScore > 0 || hScore > 0) {
            // If only one of the players has a score, this is the current hole
            currentHole = i + 1;
            break; // Break the loop as we have found the current hole
        }
        // No need for the last condition `(eScore > 0 && hScore === 0) || (eScore === 0 && hScore > 0)`
        // It's already handled by the above condition `eScore > 0 || hScore > 0`
    }

    if (currentHole > 18) {
        currentHole = 18; // Ensure we don't return a hole number that doesn't exist
    }

    return currentHole; // Return the calculated current hole
}

function generateScoresJson(viewModel) {
    var scores = {};
    for (var i = 1; i <= 18; i++) {
        scores['es' + i] = viewModel['es' + i]();
        scores['hs' + i] = viewModel['hs' + i]();
    }
    return JSON.stringify(scores);
}


function roundTotal() {
  var self = this;

  self.escore = ko.observable(0);
  self.hscore = ko.observable(0);

  self.scoreOverrideEasy = ko.observable(0);
  self.scoreOverrideMsgEasy = ko.observable(0);

  self.scoreOverrideHard = ko.observable(0);
  self.scoreOverrideMsgHard = ko.observable(0);

  self.es1 = ko.observable(0);
  self.es2 = ko.observable(0);
  self.es3 = ko.observable(0);
  self.es4 = ko.observable(0);
  self.es5 = ko.observable(0);
  self.es6 = ko.observable(0);
  self.es7 = ko.observable(0);
  self.es8 = ko.observable(0);
  self.es9 = ko.observable(0);
  self.es10 = ko.observable(0);
  self.es11 = ko.observable(0);
  self.es12 = ko.observable(0);
  self.es13 = ko.observable(0);
  self.es14 = ko.observable(0);
  self.es15 = ko.observable(0);
  self.es16 = ko.observable(0);
  self.es17 = ko.observable(0);
  self.es18 = ko.observable(0);

  self.epar1 = ko.observable(0);
  self.epar2 = ko.observable(0);
  self.epar3 = ko.observable(0);
  self.epar4 = ko.observable(0);
  self.epar5 = ko.observable(0);
  self.epar6 = ko.observable(0);
  self.epar7 = ko.observable(0);
  self.epar8 = ko.observable(0);
  self.epar9 = ko.observable(0);
  self.epar10 = ko.observable(0);
  self.epar11 = ko.observable(0);
  self.epar12 = ko.observable(0);
  self.epar13 = ko.observable(0);
  self.epar14 = ko.observable(0);
  self.epar15 = ko.observable(0);
  self.epar16 = ko.observable(0);
  self.epar17 = ko.observable(0);
  self.epar18 = ko.observable(0);

  self.easypar = ko.observable(0);
  
  self.hs1 = ko.observable(0);
  self.hs2 = ko.observable(0);
  self.hs3 = ko.observable(0);
  self.hs4 = ko.observable(0);
  self.hs5 = ko.observable(0);
  self.hs6 = ko.observable(0);
  self.hs7 = ko.observable(0);
  self.hs8 = ko.observable(0);
  self.hs9 = ko.observable(0);
  self.hs10 = ko.observable(0);
  self.hs11 = ko.observable(0);
  self.hs12 = ko.observable(0);
  self.hs13 = ko.observable(0);
  self.hs14 = ko.observable(0);
  self.hs15 = ko.observable(0);
  self.hs16 = ko.observable(0);
  self.hs17 = ko.observable(0);
  self.hs18 = ko.observable(0);
  self.hardpar = ko.observable(0);

  self.overrideOnEasy = ko.computed(function() {
    if (!!self.scoreOverrideEasy() ) {
        return true;
    }
    else {
        return false;
    }
  }, self);

  self.overrideOnHard = ko.computed(function() {
    if (!!self.scoreOverrideHard()) {
        return true;
    }
    else {
        return false;
    }
  }, self);

  self.total_easy = ko.computed(function() {
    if (!!self.scoreOverrideEasy()) {
        return wmgt.convert.to_number(self.scoreOverrideEasy());
    }
    else
    return ( 
        adjustedScore(self.es1, self.epar1) +
        adjustedScore(self.es2, self.epar2) +
        adjustedScore(self.es3, self.epar3) +
        adjustedScore(self.es4, self.epar4) +
        adjustedScore(self.es5, self.epar5) +
        adjustedScore(self.es6, self.epar6) +
        adjustedScore(self.es7, self.epar7) +
        adjustedScore(self.es8, self.epar8) +
        adjustedScore(self.es9, self.epar9) +
        adjustedScore(self.es10, self.epar10) +
        adjustedScore(self.es11, self.epar11) +
        adjustedScore(self.es12, self.epar12) +
        adjustedScore(self.es13, self.epar13) +
        adjustedScore(self.es14, self.epar14) +
        adjustedScore(self.es15, self.epar15) +
        adjustedScore(self.es16, self.epar16) +
        adjustedScore(self.es17, self.epar17) +
        adjustedScore(self.es18, self.epar18)
    )
  }, self);

  self.total_hard = ko.computed(function() {
    if (!!self.scoreOverrideHard()) {
        return wmgt.convert.to_number(self.scoreOverrideHard());
    }
    else
        return ( 
            adjustedScore(self.hs1, self.epar1) +
            adjustedScore(self.hs2, self.epar2) +
            adjustedScore(self.hs3, self.epar3) +
            adjustedScore(self.hs4, self.epar4) +
            adjustedScore(self.hs5, self.epar5) +
            adjustedScore(self.hs6, self.epar6) +
            adjustedScore(self.hs7, self.epar7) +
            adjustedScore(self.hs8, self.epar8) +
            adjustedScore(self.hs9, self.epar9) +
            adjustedScore(self.hs10, self.epar10) +
            adjustedScore(self.hs11, self.epar11) +
            adjustedScore(self.hs12, self.epar12) +
            adjustedScore(self.hs13, self.epar13) +
            adjustedScore(self.hs14, self.epar14) +
            adjustedScore(self.hs15, self.epar15) +
            adjustedScore(self.hs16, self.epar16) +
            adjustedScore(self.hs17, self.epar17) +
            adjustedScore(self.hs18, self.epar18)
        );
  }, self);

  self.easy_hard_total = ko.computed(function() {
// console.log("self.escore()", self.escore(), self.escore().length);
    if (self.escore().length == 0 || self.escore().length == 0) {
      return "-";
    }
    else
    return ( 
           wmgt.convert.to_number(self.escore()) +
           wmgt.convert.to_number(self.hscore())
           );
  }, self);


  self.currentHole = ko.computed(function(){
      let currentHole = findCurrentHoleForTwoPlayers([
            self.es1, self.es2, self.es3, self.es4, self.es5, self.es6,
            self.es7, self.es8, self.es9, self.es10, self.es11, self.es12,
            self.es13, self.es14, self.es15, self.es16, self.es17, self.es18
        ], [
            self.hs1, self.hs2, self.hs3, self.hs4, self.hs5, self.hs6,
            self.hs7, self.hs8, self.hs9, self.hs10, self.hs11, self.hs12,
            self.hs13, self.hs14, self.hs15, self.hs16, self.hs17, self.hs18
        ]);
        return currentHole;
  }); 

  self.easyMatches = ko.computed(function() {
    if (!!self.scoreOverrideEasy() || self.es18().length == 0) {
        return false;
    }
    else {
        return wmgt.convert.to_number(self.escore()) === wmgt.convert.to_number(self.total_easy());
    }
  }, self);

  self.easyError = ko.computed(function() {
    if (!!self.scoreOverrideEasy() || self.es18().length == 0) {
        return false;
    }
    else {
        return wmgt.convert.to_number(self.escore()) != wmgt.convert.to_number(self.total_easy());
    }
  }, self);

  self.hardMatches = ko.computed(function() {
    if (!!self.scoreOverrideHard() || self.hs18().length == 0) {
        return false;
    }
    else {
        return wmgt.convert.to_number(self.hscore()) === wmgt.convert.to_number(self.total_hard());
    }
  }, self);

  self.hardError = ko.computed(function() {
    if (!!self.scoreOverrideHard() || self.hs18().length == 0) {
        return false;
    }
    else {
        return wmgt.convert.to_number(self.hscore()) != wmgt.convert.to_number(self.total_hard());
    }
  }, self);

  self.saveScore = function(roundTotal, playerNo) {
    let score;
    var jsonScores = generateScoresJson(viewModel);
    let h = self.currentHole();
    if (playerNo == 1) {
       score = self.total_easy();
    }
    else {
       score = self.total_hard();
    }
    // console.log("saveScore", {h}, playerNo, score);

    apex.server.process("SAVE_SCORE",
        {x01: playerNo,
         x02: score,
         x03: h,
         x04: jsonScores,
         pageItems: '#P305_ID'
        },
        {
            success: function( pData ) {
                console.log(pData);
                if (pData.newcCurrentHole) {
                  $s("P305_CURRENT_HOLE", pData.currentHole);
                }
                else {
                    apex.region("liveStreamPlayers").refresh();
                }
            },
            error: function (pData) {
               console.error(pData);
            }
        }
    );
  };

  self.currentHole.subscribe(
   function(newVal) {
       console.log("subscription on currentHole", newVal);
       self.saveScore(self, 0);
   }.bind(self));

  self.total_easy.subscribe(
   function(newVal) {
       console.log("subscription on total_easy", newVal);
       self.saveScore(self, 1);
   }.bind(self));

  self.total_hard.subscribe(
   function(newVal) {
       console.log("subscription on total_hard", newVal);
    self.saveScore(self, 2);
   }.bind(self));


}
