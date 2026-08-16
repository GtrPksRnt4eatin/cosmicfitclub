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
    show_duplicate_date_picker(function(new_date) {
      $.post(`/models/events/${data.event_id}/duplicate`, { new_date: new_date })
       .success(function(resp) { window.location.href = '/admin/events/' + resp.id; })
       .fail(function(xhr) { alert(xhr.responseText); });
    });
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

function show_duplicate_date_picker(callback) {
  // Build modal overlay
  var overlay = document.createElement('div');
  overlay.id = 'dup_date_overlay';
  overlay.style.cssText = [
    'position:fixed','top:0','left:0','width:100%','height:100%',
    'background:rgba(0,0,0,0.65)','z-index:9999',
    'display:flex','align-items:center','justify-content:center'
  ].join(';');

  var box = document.createElement('div');
  box.style.cssText = [
    'background:#1e1e2e','border-radius:1em','padding:2em',
    'min-width:320px','box-shadow:0 8px 32px rgba(0,0,0,0.6)',
    'display:flex','flex-direction:column','gap:1em',
    'color:#eee','font-family:inherit'
  ].join(';');

  var title = document.createElement('h3');
  title.textContent = 'Duplicate Workshop';
  title.style.cssText = 'margin:0;font-size:1.2em;';

  var label = document.createElement('label');
  label.textContent = 'Select new start date:';
  label.style.cssText = 'font-size:0.9em;opacity:0.8;';

  var input = document.createElement('input');
  input.type = 'text';
  input.id   = 'dup_date_input';
  input.placeholder = 'Pick a date';
  input.style.cssText = [
    'padding:0.5em','border-radius:0.5em','border:none',
    'font-size:1em','width:100%','box-sizing:border-box',
    'background:#2e2e3e','color:#eee'
  ].join(';');

  var note = document.createElement('p');
  note.style.cssText = 'margin:0;font-size:0.8em;opacity:0.65;';
  note.textContent = 'Sessions will be shifted by the same number of days as the date difference from the original event.';

  var btnRow = document.createElement('div');
  btnRow.style.cssText = 'display:flex;gap:0.75em;justify-content:flex-end;';

  var cancelBtn = document.createElement('button');
  cancelBtn.textContent = 'Cancel';
  cancelBtn.style.cssText = 'padding:0.5em 1.2em;border-radius:0.5em;border:none;cursor:pointer;background:#444;color:#eee;';

  var confirmBtn = document.createElement('button');
  confirmBtn.textContent = 'Duplicate';
  confirmBtn.style.cssText = 'padding:0.5em 1.2em;border-radius:0.5em;border:none;cursor:pointer;background:#6c63ff;color:#fff;font-weight:bold;';

  btnRow.appendChild(cancelBtn);
  btnRow.appendChild(confirmBtn);
  box.appendChild(title);
  box.appendChild(label);
  box.appendChild(input);
  box.appendChild(note);
  box.appendChild(btnRow);
  overlay.appendChild(box);
  document.body.appendChild(overlay);

  // Init flatpickr
  var fp = flatpickr(input, {
    dateFormat: 'Y-m-d',
    defaultDate: null
  });

  cancelBtn.addEventListener('click', function() {
    fp.destroy();
    document.body.removeChild(overlay);
  });

  overlay.addEventListener('click', function(ev) {
    if(ev.target === overlay) {
      fp.destroy();
      document.body.removeChild(overlay);
    }
  });

  confirmBtn.addEventListener('click', function() {
    var val = input.value;
    if(!val) { alert('Please select a date first.'); return; }
    fp.destroy();
    document.body.removeChild(overlay);
    callback(val);
  });
}
