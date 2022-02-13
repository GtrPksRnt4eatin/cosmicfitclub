data = {
  instructors: [],
  class: {},
  schedules: [],
  locations: []
}

ctrl = {

  save_changes(e,m) {
    let payload = {
      id: m.data.class.id,
      name: m.data.class.name,
      description: m.data.class.description,
      location_id: m.data.class.location_id
    }
    $.post('/models/classdefs', payload).then( function() { get_schedules(); } );
  },

/*
  save_changes(e,m) {
    var fdata = new FormData();
    fdata.append('id', m.data.class.id);
    fdata.append('name', m.data.class.name);
    fdata.append('description', m.data.class.description);
    fdata.append('instructors', m.data.class.instructors);
    var request = new XMLHttpRequest();
    request.onreadystatechange = function() { if(request.readyState == XMLHttpRequest.DONE && request.status == 200) window.location.href='/admin/classes';  }
    request.open("POST", "/models/classdefs");
    request.send(fdata); 
    setTimeout(get_schedules,500);
  },
*/
  edit_image(e,m) {
    img_chooser.resize(500,500); 
    if(data.class.image_data && JSON.stringify(data.class.image_data) !== '{}') {
      if( data.class.image_data.original) {
        img_chooser.load_image(data.class.image_data.original.metadata.filename, data.class.image_url);
      }
      else {
        img_chooser.load_image(data.class.image_data.metadata.filename, data.class.image_url);
      }
    }
    img_chooser.show_modal(null,null,function(val) {
      popupmenu.hide();
      post_image('/models/classdefs/' + data.class.id + '/image', val['filename'], val['blob'], get_classdef);
    }); 
  },

  add_schedule(e,m)  { scheduleform.show_new();         cancelEvent(e); },
  edit_schedule(e,m) { scheduleform.show_edit(m.sched); cancelEvent(e); },
  open_schedule(e,m) { window.location = '/admin/classdef_schedule?id=' + m.sched.id; },
  del_schedule(e,m)  {
    if(!confirm('really delete this schedule?')) return;
    $.del(`/models/classdefs/schedules/${m.sched.id}`)
     .done( function() { data['schedules'].splice(m.index,1); } ); 
  }

}

$(document).ready(function() { 
  
  initialize_rivets();

  rivets.bind($('#content'), { data: data, ctrl: ctrl } );
  
  popupmenu   = new PopupMenu( id('popupmenu_container') );

  img_chooser = new AspectImageChooser();
  img_chooser.ev_sub('show', popupmenu.show );

  scheduleform = new ScheduleForm();
  scheduleform.ev_sub('show', popupmenu.show );
  scheduleform.ev_sub('after_post', function(schedule) { 
    data['schedules'].replace_or_add_by_id(schedule); 
    popupmenu.hide();
  });

  //get_staff(); //.then(function() { scheduleform.instructors = data['instructors']; } );
  get_classdef();
  get_schedules();
  

});

function initialize_rivets() {

  rivets.formatters.dayofwk    = function(val) { return moment(val).format('ddd') };
  rivets.formatters.date       = function(val) { return moment(val).format('MMM Do') };
  rivets.formatters.time       = function(val) { return moment(val).format('h:mm a') };
  rivets.formatters.fulldate   = function(val) { return moment(val).format('ddd MMM Do hh:mm a') };
  rivets.formatters.simpledate = function(val) { return moment(val).format('MM/DD/YYYY hh:mm A') };
  rivets.formatters.onlytime   = function(val) { return moment(val, [moment.ISO_8601, 'H:m:s', 'h:m a', 'H:m'] ).format('h:mm a')};

  include_rivets_rrule();
  include_rivets_dates();
  include_rivets_select();

  rivets.formatters.instructors = function(val) {
    if(empty(val)) return "";
    return val.map( function(o) { 
      obj = scheduleform.state.instructors.find( function(val) { return val.id == o; })
      return(obj && obj.name);
    })
  }

  rivets.formatters.location   = function(val) { 
    if(empty(val)) return "";
    obj = scheduleform.state.locations.find( function(x) { return x.id == val; });
    return obj ? obj.name : "";
  }

}

function get_classdef() {
  $.get('/models/classdefs/' + getUrlParameter('id'), function(resp) { data.class = resp; } )
}

function get_schedules() {
  $.get('/models/classdefs/' + getUrlParameter('id') + '/schedules', function(resp) { data.schedules = resp; } );
}

function get_staff() {
  return $.get('/models/staff', function(resp) { data.instructors = resp; } )
}

function get_locations() {
  return $.get('/models/classdefs/locations', function(resp) { data.locations = resp; } )
}