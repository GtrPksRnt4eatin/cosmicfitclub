var data = {
  subscribers: [],
  total_count: 0,
  bulk_message: ''
};

var ctrl = {
  
  refresh: function() {
    $.get('/admin/sms/subscribers', function(response) {
      data.subscribers.splice(0, data.subscribers.length, ...response.subscribers);
      data.total_count = response.total_count;
    }, 'json');
  },
  
  send_test: function() {
    var message = prompt('Enter test message:');
    if (!message) return;
    
    $.post('/admin/sms/send_test', { message: message }, 'json')
      .done(function() {
        alert('Test message sent successfully!');
      })
      .fail(function() {
        alert('Failed to send test message');
      });
  },
  
  send_individual: function(e) {
    var customer_id = $(e.target).data('id');
    var message = prompt('Enter message:');
    if (!message) return;
    
    $.post('/admin/sms/send_individual', { 
      customer_id: customer_id, 
      message: message 
    }, 'json')
      .done(function() {
        alert('Message sent successfully!');
      })
      .fail(function() {
        alert('Failed to send message');
      });
  },
  
  send_bulk: function() {
    if (!data.bulk_message) return;
    
    if (!confirm(`Send this message to ${data.total_count} subscribers?`)) return;
    
    $.post('/admin/sms/send_bulk', { 
      message: data.bulk_message 
    }, 'json')
      .done(function(response) {
        alert(`Bulk message sent to ${response.sent_count} subscribers!`);
        data.bulk_message = '';
      })
      .fail(function() {
        alert('Failed to send bulk message');
      });
  }
  
};

$(document).ready(function() {
  
  rivets.bind($('body'), { data: data, ctrl: ctrl });
  
  ctrl.refresh();
  
});
