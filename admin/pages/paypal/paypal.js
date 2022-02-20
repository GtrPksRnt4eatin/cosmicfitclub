data = {
    range: "",
    transactions: [],
    from: "",
    to: ""
  }

ctrl = {
  get_data: function(e,m) {
    var match = /(\d{4}-\d{2}-\d{2}) to (\d{4}-\d{2}-\d{2})/.exec(data['range']);
    if(!match) { return; }
    data['from'] = match[1];
    data['to'] = match[2];
    $.get('/models/staff/paypal', { from: match[1], to: match[2] }, on_paypal_data, 'json');
    history.pushState({ "from": data['from'], "to": data['to'] }, "", `paypal?from=${data['from']}&to=${data['to']}`);
  },
  dl_csv: function(e,m) {
    var match = /(\d{4}-\d{2}-\d{2}) to (\d{4}-\d{2}-\d{2})/.exec(data['range']);
    if(!match) { return; }
    window.location = '/models/staff/paypal.csv?from=' + match[1] + '&to=' + match[2];
  }
}

$(document).ready(function() {

  userview = new UserView(id('userview_container'));

  include_rivets_dates();
  include_rivets_money();

  rivets.bind( document.body, { data: data, ctrl: ctrl } );

});

function on_paypal_data(resp) {
  data.transactions = resp;
}