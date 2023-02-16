function roundTotal() {
  var self = this;
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
        return to_number(self.scoreOverride());
    }
    else
    return ( 
           to_number(self.s1()) +
           to_number(self.s2()) +
           to_number(self.s3()) +
           to_number(self.s4()) +
           to_number(self.s5()) +
           to_number(self.s6()) +
           to_number(self.s7()) +
           to_number(self.s8()) +
           to_number(self.s9()) +
           to_number(self.s10()) +
           to_number(self.s11()) +
           to_number(self.s12()) +
           to_number(self.s13()) +
           to_number(self.s14()) +
           to_number(self.s15()) +
           to_number(self.s16()) +
           to_number(self.s17()) +
           to_number(self.s18())
           ) - to_number(self.par());
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