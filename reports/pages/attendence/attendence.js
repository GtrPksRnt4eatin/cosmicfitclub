data = {
  daterange: '',
  list: []
}

ctrl = {
  get_list: function() {
    matches = /(\d{4}-\d\d-\d\d) to (\d{4}-\d\d-\d\d)/.exec(data.daterange);
    params = matches ? { from: matches[1], to: matches[2] } : {};
    $.get('attendence_list.json', params, ctrl.on_list, 'json')
  },
  on_list: function(list) { 
  	data.list = list; 
  }
}

$(document).ready( function() {
  initialize_rivets();
  ctrl.get_list();
})

function initialize_rivets() {
  include_rivets_dates();
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
}