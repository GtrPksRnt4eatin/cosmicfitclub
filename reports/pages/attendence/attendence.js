data = {
  daterange: ''
  list: []
}

ctrl = {
  on_list: function(list) { data.list = list; }
}

$(document).ready( function() {
  matches = /(\d{4}-\d\d-\d\d) to (\d{4}-\d\d-\d\d)/.exec(data.daterange);
  params = { from: matches[1], to: matches[2] };
  $.get('attendence_list.json', params, ctrl.on_list, 'json')
})