data = {
  range: "",
  payroll: [],
  from: "",
  to: ""
}

ctrl = {
  get_data: function(e,m) {
  	var match = /(\d{4}-\d{2}-\d{2}) to (\d{4}-\d{2}-\d{2})/.exec(data['range']);
  	if(!match) { return; }
    data['from'] = match[1];
    data['to'] = match[2];
    $.get('/models/staff/payroll', { from: match[1], to: match[2] }, on_payroll_data, 'json');
    history.pushState({ "from": data['from'], "to": data['to'] }, "", `payroll?from=${data['from']}&to=${data['to']}`);
  },
  dl_csv: function(e,m) {
  	var match = /(\d{4}-\d{2}-\d{2}) to (\d{4}-\d{2}-\d{2})/.exec(data['range']);
  	if(!match) { return; }
  	window.location = '/models/staff/payroll.csv?from=' + match[1] + '&to=' + match[2];
  }
}

$(document).ready(function() {

  userview = new UserView(id('userview_container'));

  data['from'] = getUrlParameter('from') ? getUrlParameter('from') : null;
  data['to']   = getUrlParameter('to')   ? getUrlParameter('to')   : null;
  if( !empty(data['from']) && !empty(['to']) ) { 
    set_range(data['from'],data['to']);  
  }

  $(window).bind('popstate', function(e) { 
    set_range(history.state.from,history.state.to);
  });

  include_rivets_dates();
  include_rivets_money();

  rivets.formatters.upcase  = function(val) { return val.toUpperCase(); }
  rivets.formatters.noempty = function(val) { return !empty(val);       }
  rivets.formatters.occlink = function(val) { return('/frontdesk/class_attendance/' + val); }

  rivets.bind( document.body, { data: data, ctrl: ctrl } );

});

function set_range(from,to) {
  data['range'] = from + ' to ' + to;
  $.get('/models/staff/payroll', { from: from, to: to }, on_payroll_data, 'json');
  history.replaceState({ "from": data['from'], "to": data['to'] }, "", `payroll?from=${data['from']}&to=${data['to']}`);
}

function on_payroll_data(resp) {
  data.payroll = resp;
}