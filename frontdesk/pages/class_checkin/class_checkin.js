data['newsheet'] = {
  classdef_id: 0,
  staff_id: 0,
  starttime: null
}

data['query_date'] = moment().toISOString().slice(0,10);

ctrl = {
  datechange:      function(e,m) {
    data['occurrences'] = [];
    var day = moment(data['query_date']).toISOString().slice(0,10);
    history.pushState({ "day": day }, "", `class_checkin?day=${day}`);
    get_calendar_events(data['query_date']);
    get_occurrences(); 
  },
  generate_sheets: function(e,m) { 
    var day = moment(data['query_date']).toISOString().slice(0,10);
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
    if(!data.newsheet.classdef_id) { $('#custom_sheet').shake(); return; }
    if(!data.newsheet.staff_id)    { $('#custom_sheet').shake(); return; }
    if(!data.newsheet.location_id) { $('#custom_sheet').shake(); return; }
    if(!data.newsheet.starttime)   { $('#custom_sheet').shake(); return; }
    $.post('/models/classdefs/occurrences', newsheet_args(), get_occurrences );
  },
  set_custom_defaults(e,m) {
    switch(parseInt(e.target.value)) {
      case 188:
        data.newsheet.location_id = 2;
        break;
      case 173:
      case 178:
        data.newsheet.location_id = 2;
        data.newsheet.staff_id = 106;
        break;
      case 174:
        data.newsheet.location_id = 1;
        data.newsheet.staff_id = 1;
        break;
    }
  }
}

$(document).ready( function() { 

  setup_bindings();
  
  userview = new UserView(id('userview_container'));

  var day = getUrlParameter('day')
  if( ! empty(day) ) { data['query_date'] = day; }
  day = moment(data['query_date']).toISOString().slice(0,10);
  history.replaceState({ "day": day }, "", `class_checkin?day=${day}`);
  get_calendar_events(day);
  
  $(window).bind('popstate', function(e) { 
    data['query_date'] = history.state.day; get_occurrences(); 
  });
  
});

window.addEventListener('pageshow', get_occurrences);

function setup_bindings() {
  include_rivets_dates();
  include_rivets_select();
  rivets.formatters.count = function(val) { return empty(val) ? 0 : val.length; }
  rivets.formatters.no_students = function(val) { return empty(val) ? true : !val.length; }
  var binding = rivets.bind( $('body'), { data: data, ctrl: ctrl } );
}

function get_calendar_events(day) {
  $.get(`/models/groups/gcal_events?day=${day}`, function(resp) { data.events = resp; }); 
}

function get_occurrences() {
  var day = moment(data['query_date']).toISOString().slice(0,10);
  $.get(`/models/classdefs/occurrences?day=${day}`, function(resp) { data['occurrences'] = resp; }, 'json');
}

function on_dropdown_click(e) {
  $(e.delegateTarget).find('.hidden').toggle();
  $(e.currentTarget).toggleClass('quarter_turn');
}

function newsheet_args() {
  var date  = moment(data.query_date);
  var match = /(\d\d):(\d\d)/.exec(data.newsheet.starttime);
  date.hours(match[1])
  date.minutes(match[2]);
  date.seconds(0);
  date.milliseconds(0);
  return {
    classdef_id: data.newsheet.classdef_id,
    staff_id:    data.newsheet.staff_id,
    location_id: data.newsheet.location_id,
    starttime:   date.format()
  }
}
