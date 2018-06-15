data = {
  daterange: '',
  list: [],
  selected_class: {}
}

ctrl = {
  get_list: function() {
    matches = /(\d{4}-\d\d-\d\d) to (\d{4}-\d\d-\d\d)/.exec(data.daterange);
    params = matches ? { from: matches[1], to: matches[2] } : {};
    $.get('attendence_list.json', params, ctrl.on_list, 'json')
  },
  on_list: function(list) { 
  	data.list = list; 
  },
  sel_class: function(e,m) {
    data.selected_class = m.cls;
  }
}

$(document).ready( function() {
  initialize_rivets();
  ctrl.get_list();
})

function initialize_rivets() {
  rivets.formatters.truncateFloat = function(value) { return value.toFixed(1); }
  rivets.formatters.is_selected = function(value) { return ( value.class_id == data.selected_class.class_id ? 'sel' : ''); }
  include_rivets_dates();
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
}