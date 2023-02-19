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
           wmgt.convert.to_number(self.es1()) +
           wmgt.convert.to_number(self.es2()) +
           wmgt.convert.to_number(self.es3()) +
           wmgt.convert.to_number(self.es4()) +
           wmgt.convert.to_number(self.es5()) +
           wmgt.convert.to_number(self.es6()) +
           wmgt.convert.to_number(self.es7()) +
           wmgt.convert.to_number(self.es8()) +
           wmgt.convert.to_number(self.es9()) +
           wmgt.convert.to_number(self.es10()) +
           wmgt.convert.to_number(self.es11()) +
           wmgt.convert.to_number(self.es12()) +
           wmgt.convert.to_number(self.es13()) +
           wmgt.convert.to_number(self.es14()) +
           wmgt.convert.to_number(self.es15()) +
           wmgt.convert.to_number(self.es16()) +
           wmgt.convert.to_number(self.es17()) +
           wmgt.convert.to_number(self.es18())
           ) - wmgt.convert.to_number(self.easypar());
  }, self);

  self.total_hard = ko.computed(function() {
    if (!!self.scoreOverrideHard()) {
        return wmgt.convert.to_number(self.scoreOverrideHard());
    }
    else
    return ( 
           wmgt.convert.to_number(self.hs1()) +
           wmgt.convert.to_number(self.hs2()) +
           wmgt.convert.to_number(self.hs3()) +
           wmgt.convert.to_number(self.hs4()) +
           wmgt.convert.to_number(self.hs5()) +
           wmgt.convert.to_number(self.hs6()) +
           wmgt.convert.to_number(self.hs7()) +
           wmgt.convert.to_number(self.hs8()) +
           wmgt.convert.to_number(self.hs9()) +
           wmgt.convert.to_number(self.hs10()) +
           wmgt.convert.to_number(self.hs11()) +
           wmgt.convert.to_number(self.hs12()) +
           wmgt.convert.to_number(self.hs13()) +
           wmgt.convert.to_number(self.hs14()) +
           wmgt.convert.to_number(self.hs15()) +
           wmgt.convert.to_number(self.hs16()) +
           wmgt.convert.to_number(self.hs17()) +
           wmgt.convert.to_number(self.hs18())
           ) - wmgt.convert.to_number(self.hardpar());
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


}
