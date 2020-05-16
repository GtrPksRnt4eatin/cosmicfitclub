ctrl = {

  save_changes(e,m) {
    var fdata = new FormData();
    fdata.append('id', m.class.id);
    fdata.append('name', m.class.name);
    fdata.append('description', m.class.description);
    fdata.append('instructors', m.class.instructors);
    if( !empty($('#pic')[0].files[0]) ) { fdata.append('image', $('#pic')[0].files[0] ); }
    var request = new XMLHttpRequest();
    request.onreadystatechange = function() { if(request.readyState == XMLHttpRequest.DONE && request.status == 200) window.location.href='/admin/classes';  }
    request.open("POST", "/models/classdefs");
    request.send(fdata); 
    setTimeout(get_schedules,500);
  },

  choose_img(e,m) {
    if(e.target.value) { m.class.image_url = e.target.value; }
  },

  edit_image(e,m) {
    img_chooser.resize(500,500); 
    if(data.class.image_data) {
      img_chooser.load_image(data.class.image_data.original.metadata.filename, data.class.image_url);
    }
    img_chooser.show_modal(null,null,function(val) {
      popupmenu.hide();
      post_image('/models/classes/' + data.class.id + '/image', val['filename'], val['blob']);
    }); 
  },

  add_schedule(e,m)  { scheduleform.show_new();         cancelEvent(e); },
  edit_schedule(e,m) { scheduleform.show_edit(m.sched); cancelEvent(e); },
  del_schedule(e,m)  {
    if(!confirm('really delete this schedule?')) return;
    $.del(`/models/classdefs/schedules/${m.sched.id}`)
     .done( function() { data['class']['schedules'].splice(m.index,1); } ); 
  }

}

$(document).ready(function() { 
  
  initialize_rivets();

  rivets.bind($('#content'), { data: data, class: data['class'], ctrl: ctrl } );
  
  popupmenu   = new PopupMenu( id('popupmenu_container') );

  img_chooser = new AspectImageChooser();
  img_chooser.ev_sub('show', popupmenu.show );

  scheduleform = new ScheduleForm();
  scheduleform.instructors = data['instructors'];
  scheduleform.ev_sub('show', popupmenu.show );
  scheduleform.ev_sub('after_post', function(schedule) { 
    data['class']['schedules'].replace_or_add_by_id(schedule); 
    popupmenu.hide();
  });

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
    if(empty(val)) return "null";
    return val.map( function(o) { 
      obj = data['instructors'].find( function(val) { return val.id == o; })
      return obj.name;
    })
  }

}

function get_schedules() {
  $.get('/models/classdefs/' + data['class_id'] + '/schedules', function(resp) { data.class.schedules = resp; } );
}

