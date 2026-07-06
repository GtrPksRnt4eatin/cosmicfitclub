data = {
  prolls: [],
  selected_proll: null,
  selected_proll_id: 0,
  edit_line: null
}

ctrl = {
  get_data: function(e,m) {
    $.get('/models/staff/payroll_reports', on_payroll_reports, 'json' );
  },

  select_report: function(e,m) {
    data.selected_proll_id = m.proll.id;
    data.selected_proll = m.proll;
  },

  open_line_edit: function(e, m) {
    var line  = m.line;
    var total = (line.value || 0) + (line.cosmic || 0) + (line.loft || 0);
    data.edit_line = {
      id:           line.id,
      description:  line.description,
      start_time:   line.start_time,
      total_cents:  total,
      total_d:      (total / 100).toFixed(2),
      value_d:      ((line.value  || 0) / 100).toFixed(2),
      loft_d:       ((line.loft   || 0) / 100).toFixed(2),
      cosmic_d:     ((line.cosmic || 0) / 100).toFixed(2),
      loft_rentals: (line.loft_rentals || 0)
    };
  },

  line_value_changed: function(e) {
    if (!data.edit_line) return;
    var val  = parseFloat(e.target.value) || 0;
    var loft = parseFloat(data.edit_line.loft_d)  || 0;
    data.edit_line.cosmic_d = (data.edit_line.total_cents / 100 - val - loft).toFixed(2);
  },

  line_loft_changed: function(e) {
    if (!data.edit_line) return;
    var val   = parseFloat(e.target.value) || 0;
    var value = parseFloat(data.edit_line.value_d) || 0;
    data.edit_line.cosmic_d = (data.edit_line.total_cents / 100 - value - val).toFixed(2);
  },

  save_line_edit: function() {
    var line   = data.edit_line;
    var value  = Math.round(parseFloat(line.value_d)  * 100);
    var loft   = Math.round(parseFloat(line.loft_d)   * 100);
    var cosmic = Math.round(parseFloat(line.cosmic_d) * 100);
    $.put('/models/staff/payroll_line/' + line.id, { value: value, cosmic: cosmic, loft: loft })
     .done(function() { data.edit_line = null; ctrl.get_data(); })
     .fail(function()  { alert('Save failed'); });
  },

  cancel_line_edit: function() {
    data.edit_line = null;
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

  rivets.formatters.not_cosmic_loft = function(val) { return val != 106; };

  rivets.bind( document.body, { data: data, ctrl: ctrl } );
  ctrl.get_data();
})

function on_payroll_reports(resp) {
  data.prolls = resp;
  if(data.selected_proll_id) {
    data.selected_proll = data.prolls.find(function(x) { return x.id == data.selected_proll_id; })
  }
}