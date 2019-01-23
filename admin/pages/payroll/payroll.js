data = {
  range: "",
  payroll: []
}

ctrl = {
  rangeselect: function(e,m) {
    var x = 5;
  },

  get_data: function(e,m) {
  	var match = /(\d{4}-\d{2}-\d{2}) to (\d{4}-\d{2}-\d{2})/.exec(data['range']);
  	if(!match) { return; }
    $.get('/models/staff/payroll', { from: match[1], to: match[2] }, on_payroll_data);
  }
}

$(document).ready(function() {
  include_rivets_dates();
  rivets.bind( document.body, { data: data, ctrl: ctrl } );
});

function on_payroll_data(resp) {
  data.payroll = resp;
}