function adjustedScore(pStrokes, holePar) {
    let strokes = wmgt.convert.to_number(pStrokes());
    let par = wmgt.convert.to_number(holePar());
    return strokes ? strokes - par : 0; // if there are no strokes count as a zero
                                        // for a better running total calculation
}

function roundTotal() {
  var self = this;

  self.score = ko.observable(0);

  /* strokes per hole */
  self.s1 = ko.observable(0);
  self.s2 = ko.observable(0);
  self.s3 = ko.observable(0);
  self.s4 = ko.observable(0);
  self.s5 = ko.observable(0);
  self.s6 = ko.observable(0);
  self.s7 = ko.observable(0);
  self.s8 = ko.observable(0);
  self.s9 = ko.observable(0);
  self.s10 = ko.observable(0);
  self.s11 = ko.observable(0);
  self.s12 = ko.observable(0);
  self.s13 = ko.observable(0);
  self.s14 = ko.observable(0);
  self.s15 = ko.observable(0);
  self.s16 = ko.observable(0);
  self.s17 = ko.observable(0);
  self.s18 = ko.observable(0);

  /* par per hole */
  self.par1 = ko.observable(0);
  self.par2 = ko.observable(0);
  self.par3 = ko.observable(0);
  self.par4 = ko.observable(0);
  self.par5 = ko.observable(0);
  self.par6 = ko.observable(0);
  self.par7 = ko.observable(0);
  self.par8 = ko.observable(0);
  self.par9 = ko.observable(0);
  self.par10 = ko.observable(0);
  self.par11 = ko.observable(0);
  self.par12 = ko.observable(0);
  self.par13 = ko.observable(0);
  self.par14 = ko.observable(0);
  self.par15 = ko.observable(0);
  self.par16 = ko.observable(0);
  self.par17 = ko.observable(0);
  self.par18 = ko.observable(0);

  self.par = ko.observable(0);
  self.scoreOverride = ko.observable(0);
  self.overrideOn = ko.computed(function() {
    if (!!self.scoreOverride()) {
        return true;
    }
    else {
        return false;
    }
  }, self);

  self.total = ko.computed(function() {
    if (!!self.scoreOverride()) {
        return wmgt.convert.to_number(self.scoreOverride());
    }
    else
    return ( 
           adjustedScore(self.s1, self.par1) +
           adjustedScore(self.s2, self.par2) +
           adjustedScore(self.s3, self.par3) +
           adjustedScore(self.s4, self.par4) +
           adjustedScore(self.s5, self.par5) +
           adjustedScore(self.s6, self.par6) +
           adjustedScore(self.s7, self.par7) +
           adjustedScore(self.s8, self.par8) +
           adjustedScore(self.s9, self.par9) +
           adjustedScore(self.s10, self.par10) +
           adjustedScore(self.s11, self.par11) +
           adjustedScore(self.s12, self.par12) +
           adjustedScore(self.s13, self.par13) +
           adjustedScore(self.s14, self.par14) +
           adjustedScore(self.s15, self.par15) +
           adjustedScore(self.s16, self.par16) +
           adjustedScore(self.s17, self.par17) +
           adjustedScore(self.s18, self.par18)
           );
  }, self);

  self.submissionMatches = ko.computed(function() {
    if (!!self.scoreOverride() || self.s18().length == 0 || self.score().length == 0 || $v("P9_ID").length == 0) {
        return false;
    }
    else {
        return wmgt.convert.to_number(self.score()) === wmgt.convert.to_number(self.total());
    }
  }, self);

  self.scoreError = ko.computed(function() {
    if ($v("P9_WHAT_IF") === "Y") {
        return false;
    }
    else
    if (!!self.scoreOverride() || self.s18().length == 0 || self.score().length == 0) {
        return false;
    }
    else {
        return wmgt.convert.to_number(self.score()) != wmgt.convert.to_number(self.total());
    }
  }, self);

}

// view hole preview
function viewH(el) {
  let hLabel, H;
  let elID = el.id;
  hLabel = elID.split("_")[1];
  H = hLabel.split("H")[1];

  if (!H) {
    // we do not have a Hole number, abort
    return;
  }

  $s("P9_H", H);

  apex.region("holePreview").refresh();
  $("#holePreview").popup("open");
}

function qhide(pID) {
  $("[data-id=" + pID + "]").parents("tr").slideUp();
}


