data = {
  class: {},
  schedules: []
}

ctrl = {

  save_changes(e,m) {
    let payload = {
      id: data.class.id,
      name: data.class.name,
      description: data.class.description,
      location_id: data.class.location_id
    }
    $.post('/models/classdefs', payload);
  },

  edit_name(e,m) {
    edit_text.show('Edit Class Name', data.class.name, function(val) {
      data.class.name = val;
      ctrl.save_changes();
    });
  },

  edit_description(e,m) {
    edit_text.show_long('Edit Class Description', data.class.description, function(val) {
      data.class.description = val;
      ctrl.save_changes();
    });
  },

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

  open_schedule(e,m) { window.location = '/admin/classdef_schedule?id=' + m.sched.id; },

  new_schedule(e,m) {
    window.location = '/admin/classdef_schedule?classdef_id=' + data.class.id;
  },

  force_del(e,m) {
    if (!confirm(`Permanently delete "${m.data.class.name}"? This cannot be undone.`)) return;
    $.del(`/models/classdefs/${m.data.class.id}/force`)
     .done( function() { window.location = '/admin/classes'; });
  }

}

$(document).ready(function() { 
  
  rivets.bind($('#content'), { data: data, ctrl: ctrl } );

  userview    = new UserView( id('userview_container') );
  popupmenu   = new PopupMenu( id('popupmenu_container') );

  edit_text = new EditText();
  edit_text.ev_sub('show', popupmenu.show);
  edit_text.ev_sub('done', function() { popupmenu.hide(); });

  img_chooser = new AspectImageChooser();
  img_chooser.ev_sub('show', popupmenu.show );

  get_classdef();
  get_schedules();

});

window.addEventListener('pageshow', function(e) {
  if (e.persisted) { get_schedules(); }
});

function get_classdef() {
  $.get('/models/classdefs/' + getUrlParameter('id'), function(resp) { data.class = resp; } )
}

function get_schedules() {
  $.get('/models/classdefs/' + getUrlParameter('id') + '/schedules', function(resp) { data.schedules = resp; } );
}

