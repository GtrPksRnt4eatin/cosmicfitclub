var data = {
  phone: '',
  agreed_to_terms: false,
  opted_in: false,
  opt_in_date: null,
  error: null
};

var ctrl = {
  
  opt_in: function() {
    if (!data.phone || !data.agreed_to_terms) return;
    
    $.post('/sms/opt-in', {
      phone: data.phone
    }, 'json')
      .done(function(response) {
        data.opted_in = true;
        data.opt_in_date = response.opt_in_date;
        data.error = null;
        alert('Success! You will now receive SMS notifications.');
      })
      .fail(function(xhr) {
        data.error = xhr.responseJSON ? xhr.responseJSON.error : 'An error occurred. Please try again.';
      });
  },
  
  opt_out: function() {
    if (!confirm('Are you sure you want to unsubscribe from SMS notifications?')) return;
    
    $.post('/sms/opt-out', {}, 'json')
      .done(function() {
        data.opted_in = false;
        data.opt_in_date = null;
        alert('You have been unsubscribed from SMS notifications.');
      })
      .fail(function(xhr) {
        data.error = xhr.responseJSON ? xhr.responseJSON.error : 'An error occurred. Please try again.';
      });
  },
  
  load_status: function() {
    $.get('/sms/status', function(response) {
      data.opted_in = response.opted_in;
      data.opt_in_date = response.opt_in_date;
      data.phone = response.phone || '';
    }, 'json');
  }
  
};

$(document).ready(function() {
  
  var userview = new UserView(id('userview_container'));
  
  rivets.bind($('body'), { data: data, ctrl: ctrl });
  
  // Format phone number as user types
  $('input[type="tel"]').on('input', function() {
    var value = $(this).val().replace(/\D/g, '');
    if (value.length >= 10) {
      value = value.substring(0, 10);
      var formatted = '(' + value.substring(0, 3) + ') ' + value.substring(3, 6) + '-' + value.substring(6, 10);
      $(this).val(formatted);
      data.phone = formatted;
    }
  });
  
  // Load current opt-in status when user logs in
  userview.ev_sub('on_user', function() {
    ctrl.load_status();
  });
  
  // If already logged in, load status immediately
  if (userview.logged_in) {
    ctrl.load_status();
  }
  
});
