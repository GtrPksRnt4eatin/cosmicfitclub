ctrl = {

  edit_heading: function(e,m) {
    edit_text.show(
      "Edit Event Title",  
      data.event.name, 
      function(val) { data.event.name = val; ctrl.save_changes(); } 
    )
  },

  edit_subheading: function(e,m) {
    edit_text.show(
      "Edit Event Subheading",  
      data.event.subheading, 
      function(val) { data.event.subheading = val; ctrl.save_changes(); } 
    )
  },

  edit_image: function(e,m) {
    img_chooser.resize(500,500); 
    if(data.event.image_data) {
      img_chooser.load_image(data.event.image_data.original.metadata.filename, data.event.image_url);
    }
    img_chooser.show_modal(null,null,function(val) {
      popupmenu.hide();
      post_image('/models/events/' + data.event.id + '/image', val['filename'], val['blob'], fetch_event);
    }); 
  },

  edit_image_wide: function(e,m) {
    img_chooser.resize(1920,1080); 
    if(data.event.wide_image) {
      img_chooser.load_image( data.event.wide_image.image_data.metadata.filename, data.event.wide_image.url );
    }
    img_chooser.show_modal(null,null,function(val) {
      popupmenu.hide();
      post_image('/models/events/' + data.event.id + '/image_wide', val['filename'], val['blob']);
    }); 
  },

  edit_poster_lines: function(e,m) {
    edit_text_array.show("Edit Poster Lines", data.event.poster_lines, function(val) { data.event.poster_lines = val; ctrl.save_changes(); })
  },

  edit_short_url: function(e,m) {
    if(!data.event.short_url) { data.event.short_url = { short_path: "" }; } 
    edit_text.show(
      "Edit Event Short URL", 
      data.event.short_url.short_path, 
      function(val) { 
        data.event.short_url.short_path = val; 
        $.post('/models/events/' + data.event.id + '/short_url', { short_url: val } )
         .done( function() { fetch_event(); } )
      },
      function(val) {
        if (!val.match(/^[a-z0-9_]*$/i)) { return ["Only lowercase letters, numbers, underscores allowed."]; }
        return [];
      }
    )
  },

  edit_description: function(e,m) {
    edit_text.show_long(
      "Edit Event Description", 
      data.event.description, 
      function(val) { data.event.description = val; ctrl.save_changes(); },
      function(val) { 
        if(val.length>300) { return ["300 Characters Max"]; }
        return [];
      }
    )
  },

  edit_details: function(e,m) {
    edit_text.show_long("Edit Event Details", data.event.details, function(val) { data.event.details = val; ctrl.save_changes(); } )
  },

  update_hidden: function(e,m) {
    data.event.hidden = !e.target.checked;
    ctrl.save_changes();
  },

  save_changes(e,m) {
    var fd = new FormData();
    fd.append('id', data.event_id);
    fd.append('name', data.event.name);
    fd.append('subheading', data.event.subheading);
    fd.append('poster_lines', JSON.stringify(data.event.poster_lines));
    fd.append('description', data.event.description);
    fd.append('details', data.event.details);
    fd.append('hidden', data.event.hidden);
    fd.append('mode', data.event.mode);
    fd.append('registration_url', data.event.registration_url);
    var request = new XMLHttpRequest();
    request.open("POST", "/models/events");
    request.send(fd);
  },

  add_collaborator(e,m)  { collabform.show_new(data.event.id); cancelEvent(e); },
  edit_collaborator(e,m) { collabform.show_edit(m.collab);     cancelEvent(e); },
  del_collaborator(e,m)  {
    if(!confirm('really delete this collaboration?')) return;
    $.del(`/models/events/collabs/${m.collab.id}`)
     .done( function() { data['event']['collaborations'].splice(m.index,1); });
  },

  add_session(e,m)  { sessionform.show_new();        cancelEvent(e); },
  edit_session(e,m) { sessionform.show_edit(m.sess); cancelEvent(e); },
  del_session(e,m)  {
    if(!confirm('really delete this session?')) return;
    $.del(`/models/events/sessions/${m.sess.id}`)
     .done( function() { data['event']['sessions'].splice(m.index,1); } );
  },
  
  add_price(e,m)  { priceform.show_new();          cancelEvent(e); },
  edit_price(e,m) { priceform.show_edit(m.price);  cancelEvent(e); },
  del_price(e,m)  {
    if(!confirm('really delete this price?')) return;
    $.del(`/models/events/prices/${m.price.id}`)
     .done( function() { data['event']['prices'].splice(m.index,1); } ); 
  },

  choose_img(e,m) {
    if(e.target.value) { m.event.image_url = e.target.value; }
  },

  view_checkout(e,m) {
    window.location.href="/checkout/event/" + data.event.id;
  },

  view_attendance(e,m) {
    window.location.href="/frontdesk/event_attendance/" + data.event.id;
  },

  delete_event(e,m) {
    $.del(`/models/events/${m.data.event_id}`)
     .success(function() { window.location.href='/admin/events'; })
     .fail(function(xhr) { alert(xhr.responseText); });
  },
  
  duplicate_event(e,m) {
    $.post(`/models/events/${data.event_id}/duplicate`)
     .success(function() { window.location.href='/admin/events'; })
     .fail(function(xhr) { alert(xhr.responseText); });
  }
  
}

$(document).ready(function() { 
  
  include_rivets_select();
  setup_rivets();

  popupmenu       = new PopupMenu(id('popupmenu_container'));
  //custy_selector  = new CustySelector();
  img_chooser     = new AspectImageChooser();
  edit_text       = new EditText();
  edit_text_array = new EditTextArray();

  sessionform = new SessionForm();
  sessionform.ev_sub('show', popupmenu.show );
  sessionform.ev_sub('after_post', function(sess) {
    var i = data['event']['sessions'].findIndex( function(obj) { return obj['id'] == sess['id']; });
    if(i != -1) { data['event']['sessions'][i] = sess;  }
    else        { data['event']['sessions'].push(sess); }
    sortSessions();
    popupmenu.hide();
  });

  priceform   = new PriceForm();
  priceform.ev_sub('show',   popupmenu.show );
  priceform.ev_sub('after_post', function(price) {
    var i = data['event']['prices'].findIndex( function(obj) { return obj['id'] == price['id']; });
    if(i != -1) { data['event']['prices'][i] = price;  }
    else        { data['event']['prices'].push(price); }
    popupmenu.hide();
  });

  collabform = new EventCollabForm();
  collabform.ev_sub('show',   popupmenu.show );
  collabform.ev_sub('after_post', function(collab) {
    var i = data['event']['collaborations'].findIndex( function(obj) { return obj['id'] == collab['id']; });
    if(i != -1) { data['event']['collaborations'][i] = collab;  }
    else        { data['event']['collaborations'].push(collab); }
    popupmenu.hide(); 
  });

  img_chooser.ev_sub('show', popupmenu.show );

  edit_text.ev_sub('show', popupmenu.show );
  edit_text.ev_sub('done', function(val) { popupmenu.hide(); } );

  edit_text_array.ev_sub('show', popupmenu.show );
  edit_text_array.ev_sub('done', function(val) { popupmenu.hide(); } );

  //custy_selector.ev_sub('show', popupmenu.show );
  //custy_selector.ev_sub('close_modal', function(val) { popupmenu.hide(); } );

  //sortSessions();

});

function setup_rivets() {
  include_rivets_dates();

  rivets.formatters.invert = function(val) { return(!val); }
  rivets.formatters.eq = function(val, arg) { return val == arg; }

  rivets.formatters.session_names = function(arr) {
    if(empty(arr)) return arr;
    return arr.map(function(id) {
      var sess = data.event.sessions.find( function(sess) { return sess.id == id } )
      return ( sess && sess.title );
    }).join(',');
  }

  rivets.formatters.event_checkout_url = function(val) { return "/checkout/event/" + val; }
  
  rivets.bind($('#content'), { data: data, ctrl: ctrl } );
  fetch_event();
}

function sortSessions() {
  data.event.sessions.sort( function(a,b) {
    return moment(a.start_time) - moment(b.start_time); 
  });
}

function fetch_event() {
  $.get('/models/events/' + data.event_id + '/admin_detail', function(val) { data.event = val; sortSessions(); } )
}
