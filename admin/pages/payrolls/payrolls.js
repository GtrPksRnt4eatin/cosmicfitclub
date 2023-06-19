data = {
  prolls: [],
  selected_proll: null,
  selected_proll_id: 0
}

ctrl = {
  get_data: function(e,m) {
    $.get('/models/staff/payroll_reports', on_payroll_reports, 'json' );
  },

  select_report: function(e,m) {
    data.selected_proll_id = m.proll.id;
    data.selected_proll = m.proll;
  },

  payout_now: function(e,m) {
    let start = moment.parseZone(data.selected_proll.start_date).format("MM-DD");
    let end   = moment.parseZone(data.selected_proll.end_date).format("MM-DD");
    let params = { 
      amount:                e.target.dataset.value,
      stripe_connected_acct: e.target.dataset.stripeid,
      descriptor:            `${start} to ${end} ${e.target.dataset.descriptor}`,
      slip_id:               m.slip ? m.slip.id : null,
      staff_id:              m.slip ? m.slip.staff.id : null,
      payroll_id:            data.selected_proll.id,
      tag:                   e.target.dataset.tag || "pay_slip"
    }
    $.post('/models/staff/payout', params, 'json')
     .success( function(resp) { console.log(resp); alert("success"); ctrl.get_data(); })
     .fail( function(e,xhr) { console.log(e); alert("failure"); })
  }
}

$(document).ready(function() { 
  userview = new UserView(id('userview_container'));

  include_rivets_dates();
  include_rivets_money();

  rivets.formatters.descriptor = function(val, str) {
    let start = moment.parseZone(data.selected_proll.start_date).format("MM-DD");
    let end   = moment.parseZone(data.selected_proll.end_date).format("MM-DD");
    return `${start} to ${end} ${str}`; 
  }

  rivets.bind( document.body, { data: data, ctrl: ctrl } );
  ctrl.get_data();
})

function on_payroll_reports(resp) {
  data.prolls = resp;
  if(data.selected_proll_id) {
    data.selected_proll = data.prolls.find(function(x) { return x.id == data.selected_proll_id; })
  }
}