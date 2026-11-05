data = {
  range: "",
  payroll: [],
  from: "",
  to: "",
  stripe_pnl_generating: false,
  stripe_pnl_button_text: 'Generate Stripe P&L Sheet'
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
    if(!(data['from'] && data['to'])) { return; }
  	window.location = '/models/staff/payroll.csv?from=' + data['from'] + '&to=' + data['to'];
  },
  dl_payouts: function(e,m) {
  	if(!(data['from'] && data['to'])) { return; }
    window.location = '/models/staff/payouts.csv?from=' + data['from'] + '&to=' + data['to'];
  },
  send_to_drive: function(e,m) {
    if(!(data['from'] && data['to'])) { return; }
    $.get('/models/staff/payroll2drive', { from: data['from'], to: data['to'] }, on_save_to_drive);
  },
  generate_stripe_pnl: function(e,m) {
    if(data['stripe_pnl_generating']) { return; }
    if(!(data['from'] && data['to'])) { return; }
    set_stripe_pnl_generating(true);
    $.get('/models/staff/stripe_pnl_sheet', { from: data['from'], to: data['to'] })
     .done(function(resp) {
       if(resp && resp.job_id) {
         poll_stripe_pnl_job(resp.job_id, 0);
         return;
       }
       if(resp && resp.url) {
          set_stripe_pnl_generating(false);
         on_save_to_drive(resp);
         return;
       }
       set_stripe_pnl_generating(false);
       alert('Stripe P&L job started, but no job id was returned.');
     })
     .fail(function(err) {
       set_stripe_pnl_generating(false);
       var msg = 'Failed to create Stripe P&L sheet';
       if(err && err.responseJSON && err.responseJSON.error) {
         msg = err.responseJSON.error;
       } else if(err && err.responseText) {
         msg = err.responseText;
       }
       alert(msg);
       console.log(err);
     });
  },
  generate_payroll: function(e,m) {
    $.post('/models/staff/payroll', { from: data['from'], to: data['to'] })
     .done( function() { window.location = '/admin/payrolls'} )
     .fail( function(e,xhr) { alert('Failed: ' + e); } )
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

function poll_stripe_pnl_job(jobId, attempts) {
  var maxAttempts = 150;
  var delayMs = 2000;

  if(attempts >= maxAttempts) {
    set_stripe_pnl_generating(false);
    alert('Stripe P&L generation timed out. Please try again with a smaller date range.');
    return;
  }

  setTimeout(function() {
    $.get('/models/staff/stripe_pnl_sheet_status', { job_id: jobId })
      .done(function(resp) {
        if(!resp || !resp.status) {
          poll_stripe_pnl_job(jobId, attempts + 1);
          return;
        }

        if(resp.status === 'completed' && resp.url) {
          set_stripe_pnl_generating(false);
          on_save_to_drive(resp);
          return;
        }

        if(resp.status === 'failed') {
          set_stripe_pnl_generating(false);
          alert(resp.error || 'Stripe P&L job failed');
          return;
        }

        poll_stripe_pnl_job(jobId, attempts + 1);
      })
      .fail(function(err) {
        console.log(err);
        poll_stripe_pnl_job(jobId, attempts + 1);
      });
  }, delayMs);
}

function set_stripe_pnl_generating(isGenerating) {
  data['stripe_pnl_generating'] = !!isGenerating;
  data['stripe_pnl_button_text'] = isGenerating ? 'Generating Stripe P&L…' : 'Generate Stripe P&L Sheet';
}

function on_payroll_data(resp) {
  data.payroll = resp;
}

function on_save_to_drive(resp) {
  window.location = resp.url;
}
