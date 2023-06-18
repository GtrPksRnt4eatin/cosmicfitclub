data = {
  prolls: []
}

ctrl = {
  get_data: function(e,m) {
    $.get('/models/staff/payroll_reports', on_payroll_reports, 'json' );
  }
}

$(document).ready(function() { 
  userview = new UserView(id('userview_container'));

  include_rivets_dates();
  include_rivets_money();

  rivets.bind( document.body, { data: data, ctrl: ctrl } );
  ctrl.get_data();
})

function on_payroll_reports(resp) {
  data.prolls = resp;
}