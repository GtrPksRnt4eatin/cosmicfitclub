data['newsheet'] = {
  classdef_id: 0,
  staff_id: 0,
  starttime: null
}

data['query_date'] = new Date().setHours(0, 0, 0, 0);

ctrl = {
  datechange:      function(e,m) {
    data['occurrences'] = [];
    var day = new Date(data['query_date']).toISOString();
    history.pushState({ "day": day }, "", `class_checkin?day=${day}`); 
    get_occurrences(); 
  },
  generate_sheets: function(e,m) { 
    var day = new Date(data['query_date']).toISOString();
    $.post(`/models/classdefs/generate?day=${day}`, get_occurrences); 
  },
  delete: function(e,m) {
    $.del(`/models/classdefs/occurrences/${m.occur.id}`, get_occurrences, 'json');
    cancelEvent(e);
  },
  edit:   function(e,m) {
    window.location.href = `class_attendance/${m.occur.id}`;
    cancelEvent(e);
  },
  edit_customer(e,m) {
    window.location.href = '/frontdesk/customer_file?id=' + m.res.customer_id;
  },
  dropdown(e,m) {
    data.occurrences[m.index].visible = !data.occurrences[m.index].visible;
  },
  create_custom(e,m) {
    if(!data.newsheet.classdef_id) { $('#custom_form').shake(); return; }
    if(!data.newsheet.staff_id)    { $('#custom_form').shake(); return; }
    if(!data.newsheet.starttime)   { $('#custom_form').shake(); return; }
    $.post('/models/classdefs/occurrences', JSON.Stringify(data.reservation), get_occurrences );
  }
}

$(document).ready( function() { 

  setup_bindings();
  
  userview = new UserView(id('userview_container'));

  var day = getUrlParameter('day')
  if( ! empty(day) ) { data['query_date'] = day; }
  day = new Date(data['query_date']).toISOString();
  history.replaceState({ "day": day }, "", `class_checkin?day=${day}`);

  $(window).bind('popstate', function(e) { 
    data['query_date'] = history.state.day; get_occurrences(); 
  });

  get_occurrences();

});

function setup_bindings() {
  include_rivets_dates();
  include_rivets_select();
  rivets.formatters.count = function(val) { return empty(val) ? 0 : val.length; }
  rivets.formatters.no_students = function(val) { return empty(val) ? true : !val.length; }
  var binding = rivets.bind( $('body'), { data: data, ctrl: ctrl } );
}

function get_occurrences() {
  var day = new Date(data['query_date']).toISOString();
  $.get(`/models/classdefs/occurrences?day=${day}`, function(resp) { data['occurrences'] = resp; }, 'json');
}

function on_dropdown_click(e) {
  $(e.delegateTarget).find('.hidden').toggle();
  $(e.currentTarget).toggleClass('quarter_turn');
}