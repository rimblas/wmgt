function roundTotal() {
  var self = this;

  self.score = ko.observable(0);

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
           wmgt.convert.to_number(self.s1()) +
           wmgt.convert.to_number(self.s2()) +
           wmgt.convert.to_number(self.s3()) +
           wmgt.convert.to_number(self.s4()) +
           wmgt.convert.to_number(self.s5()) +
           wmgt.convert.to_number(self.s6()) +
           wmgt.convert.to_number(self.s7()) +
           wmgt.convert.to_number(self.s8()) +
           wmgt.convert.to_number(self.s9()) +
           wmgt.convert.to_number(self.s10()) +
           wmgt.convert.to_number(self.s11()) +
           wmgt.convert.to_number(self.s12()) +
           wmgt.convert.to_number(self.s13()) +
           wmgt.convert.to_number(self.s14()) +
           wmgt.convert.to_number(self.s15()) +
           wmgt.convert.to_number(self.s16()) +
           wmgt.convert.to_number(self.s17()) +
           wmgt.convert.to_number(self.s18())
           ) - wmgt.convert.to_number(self.par());
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
