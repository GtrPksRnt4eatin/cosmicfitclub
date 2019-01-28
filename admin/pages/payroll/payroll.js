data = {
  range: "",
  payroll: []
}

ctrl = {
  get_data: function(e,m) {
  	var match = /(\d{4}-\d{2}-\d{2}) to (\d{4}-\d{2}-\d{2})/.exec(data['range']);
  	if(!match) { return; }
    $.get('/models/staff/payroll', { from: match[1], to: match[2] }, on_payroll_data);
  },
  dl_csv: function(e,m) {
  	var match = /(\d{4}-\d{2}-\d{2}) to (\d{4}-\d{2}-\d{2})/.exec(data['range']);
  	if(!match) { return; }
  	window.location = '/models/staff/payroll.csv?from=' + match[1] + '&to=' + match[2];
  }
}

$(document).ready(function() {
  include_rivets_dates();
  rivets.bind( document.body, { data: data, ctrl: ctrl } );
});

function on_payroll_data(resp) {
  data.payroll = resp;
}