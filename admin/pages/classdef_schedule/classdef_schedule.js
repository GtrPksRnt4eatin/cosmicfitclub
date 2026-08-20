var original = null;

data = {
  sched: {},
  instructors: [],
  locations: [],
  story_status: ''
}

ctrl = {

  edit_image: function(e,m) {
    img_chooser.resize(500,500); 
    if(data.sched.image_data) {
      img_chooser.load_image(data.sched.image_data.original.metadata.filename, data.sched.image_url);
    }
    img_chooser.show_modal(null,null,function(val) {
      popupmenu.hide();
      post_image('/models/classdefs/schedules/' + data.sched.id + '/image', val['filename'], val['blob'], get_sched_details);
    }); 
  },

  save_changes: function(e,m) {
    var sel = $('#instructor_select')[0].selectize;
    var classdef_id = data.sched.classdef_id || getUrlParameter('classdef_id');
    if (!classdef_id) return;
    var instructors = sel ? sel.getValue() : data.sched.instructors;
    var rrule       = data.sched.rrule_raw;
    var start_time  = $('#start_time').val() || data.sched.start_time;
    var end_time    = $('#end_time').val()   || data.sched.end_time;
    if (!rrule || !start_time || !end_time || !instructors || instructors.length === 0) return;
    var payload = {
      id:          data.sched.id || 0,
      instructors: instructors,
      rrule:       rrule,
      start_time:  start_time,
      end_time:    end_time,
      location_id: data.sched.location_id,
      capacity:    data.sched.capacity
    };
    if (original && JSON.stringify(payload) === JSON.stringify(original)) return;
    original = Object.assign({}, payload);
    $.post('/models/classdefs/' + classdef_id + '/schedules', JSON.stringify(payload))
     .done(function(resp) {
       if (!data.sched.id) {
         history.replaceState(null, '', '/admin/classdef_schedule?id=' + resp.id);
       }
       get_sched_details();
     });
  },

  upload_video: function(e,m) {
    if (e.target.files && e.target.files[0]) {
      var fd = new FormData();
      fd.append('video', e.target.files[0], e.target.files[0].name);
      var request = new XMLHttpRequest();
      request.open("POST", "/models/classdefs/schedules/" + data.sched.id + "/video", true);
      request.onload = function(e) { get_sched_details(); }
      request.onerror = function(e) { alert("Failed to Upload Video"); }
      request.send(fd);
    }
  },

  post_ig_video_story: function(e,m) {
    data.story_status = 'Posting to IG...';
    $.post('/integrations/facebook/ig_video_story_for_sched/' + data.sched.id)
     .success(function(resp) { data.story_status = 'Posted to Instagram!'; })
     .fail(function(req)     { data.story_status = 'Failed: ' + req.responseText; });
  },

  post_fb_video_story: function(e,m) {
    data.story_status = 'Posting to FB...';
    $.post('/integrations/facebook/fb_video_story_for_sched/' + data.sched.id)
     .success(function(resp) { data.story_status = 'Posted to Facebook!'; })
     .fail(function(req)     { data.story_status = 'Failed: ' + req.responseText; });
  },

  delete_schedule: function(e,m) {
    if (!confirm('Delete this schedule? This cannot be undone.')) return;
    $.del('/models/classdefs/schedules/' + data.sched.id)
     .done(function() { window.location = '/admin/edit_class?id=' + data.sched.classdef_id; });
  }

}

$(document).ready(function() {

  userview       = new UserView( id('userview_container') );
  popupmenu      = new PopupMenu( id('popupmenu_container') );
  edit_text      = new EditText();
  img_chooser    = new AspectImageChooser();

  img_chooser.ev_sub('show', popupmenu.show );
  img_chooser.ev_sub('image_cropped', function(val) {
    popupmenu.hide();
    fd = new FormData(); 
    fd.append('image', val['blob'], val['filename'] ); 
    request = new XMLHttpRequest();
    request.open( "POST", "/models/classdefs/schedules/" + data.sched.id + "/image", true );
    request.onload  = function(e) { get_sched_details(); }
    request.onerror = function(e) { alert("Failed to Upload Image"); }
    request.send(fd);
  });

  edit_text.ev_sub('show', popupmenu.show );
  edit_text.ev_sub('done', popupmenu.hide );
  popupmenu.ev_sub('close', edit_text.cancel);

  init_rivets();

  get_locations().then(get_staff).then(function() {
    $('#instructor_select').selectize({
      plugins: ['remove_button'],
      onChange: function() { ctrl.save_changes(); }
    });
    $('#start_time, #end_time').timepicker({ timeFormat: 'h:i A', step: 15, scrollDefault: 'now' });
    if (getUrlParameter('id')) {
      get_sched_details();
    } else {
      apply_new_schedule_defaults();
      populate_instructor_select();
    }
  });

});

function init_rivets() {
  include_rivets_dates();
  include_rivets_select();
  rivets.formatters.teachernames = function(val) { return val ? val.map(function(x) { return x.name }).join(', ') : ''; }
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
}

function get_sched_details() {
  var id = getUrlParameter('id');
  if (!id) return;
  $.get( "/models/classdefs/schedules/" + id, function(resp) {
    data.sched = resp;
    populate_instructor_select();
  });
}

function get_staff() {
  return $.get('/models/staff', function(resp) { data.instructors = resp; });
}

function get_locations() {
  return $.get('/models/classdefs/locations', function(resp) { data.locations = resp; });
}

function apply_new_schedule_defaults() {
  var classdef_id = getUrlParameter('classdef_id');
  data.sched = {
    rrule_raw:   'FREQ=WEEKLY;BYDAY=MO;INTERVAL=1',
    location_id: 2,
    start_time:  '9:00:00',
    end_time:    '10:00:00',
    capacity:    20,
    classdef_id: parseInt(classdef_id)
  };
  $('#start_time').timepicker('setTime', '9:00 AM');
  $('#end_time').timepicker('setTime', '10:00 AM');
  if (classdef_id) {
    $.get('/models/classdefs/' + classdef_id, function(resp) {
      data.sched.classdef    = resp;
      data.sched.classdef_id = resp.id;
    });
  }
}

function populate_instructor_select() {
  var $el = $('#instructor_select')[0];
  if (!$el || !$el.selectize) return;
  var sel = $el.selectize;
  sel.clearOptions();
  (data.instructors || []).forEach(function(inst) {
    sel.addOption({ value: inst.id, text: inst.name });
  });
  sel.setValue(data.sched.instructors || [], true);
  if (data.sched.start_time) { $('#start_time').timepicker('setTime', data.sched.start_time); }
  if (data.sched.end_time)   { $('#end_time').timepicker('setTime', data.sched.end_time); }
  // snapshot current state so save_changes can detect real changes
  original = {
    id:          data.sched.id,
    instructors: (data.sched.instructors || []).slice(),
    rrule:       data.sched.rrule_raw,
    start_time:  data.sched.start_time,
    end_time:    data.sched.end_time,
    location_id: data.sched.location_id,
    capacity:    data.sched.capacity
  };
  // attach change handlers only after values are set
  $('#start_time, #end_time').off('changeTime').on('changeTime', function() {
    var field = this.id === 'start_time' ? 'start_time' : 'end_time';
    data.sched[field] = $(this).val();
    ctrl.save_changes();
  });
}