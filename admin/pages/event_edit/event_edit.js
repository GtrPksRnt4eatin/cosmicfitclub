ctrl = {

  edit_image: function(e,m) {
    if(data.staff.image_data) {
      img_chooser.edit_image(data.staff.image_data.original.metadata.filename, data.staff.image_url);
    }
    img_chooser.show_modal(); 
  },

  save_changes(e,m) {
    var fd = new FormData();
    fd.append('id', m.event.id);
    fd.append('name', m.event.name);
    fd.append('description', m.event.description);
    fd.append('details', m.event.details);
    if( !empty(m.event.sessions[0])   ) { fd.append('starttime', m.event.sessions[0].start_time); }
    if( !empty($('#pic')[0].files[0]) ) { fd.append('image', $('#pic')[0].files[0] ); }
    var request = new XMLHttpRequest();
    request.onreadystatechange = function() { if(request.readyState == XMLHttpRequest.DONE && request.status == 200) window.location.href='/admin/events';  }
    request.open("POST", "/models/events");
    request.send(fd);
  },

  
  add_price(e,m)  { priceform.show_new();          cancelEvent(e); },
  edit_price(e,m) { priceform.show_edit(m.price);  cancelEvent(e); },
  del_price(e,m)  {
    if(!confirm('really delete this price?')) return;
    $.del(`/models/events/prices/${m.price.id}`)
     .done( function() { data['event']['prices'].splice(m.index,1); } ); 
  },

  add_session(e,m)  { sessionform.show_new();        cancelEvent(e); },
  edit_session(e,m) { sessionform.show_edit(m.sess); cancelEvent(e); },
  del_session(e,m)  {
    if(!confirm('really delete this session?')) return;
    $.del(`/models/events/sessions/${m.sess.id}`)
     .done( function() { data['event']['sessions'].splice(m.index,1); } );
  },

  choose_img(e,m) {
    if(e.target.value) { m.event.image_url = e.target.value; }
  }
  
}

$(document).ready(function() { 
  
  setup_rivets();

  popupmenu   = new PopupMenu(id('popupmenu_container'));
  img_chooser = new AspectImageChooser();

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

  img_chooser.ev_sub('show', popupmenu.show );
  img_chooser.ev_sub('image_cropped', function(val) {
    popupmenu.hide();
  }

  id("pic").onchange = function () {
    var reader = new FileReader();
    reader.onload = function (e) { id("picpreview").src = e.target.result; };
    reader.readAsDataURL(this.files[0]);
  };

  sortSessions();

});

function setup_rivets() {
  include_rivets_dates();

  rivets.formatters.session_names = function(arr) {
    if(empty(arr)) return arr;
    return arr.map(function(id) {
      var sess = data.event.sessions.find( function(sess) { return sess.id == id } )
      return ( sess && sess.title );
    }).join(',');
  }
  
  rivets.bind($('#content'), { event: data['event'], ctrl: ctrl } );
}

function sortSessions() {
  data['event']['sessions'].sort( function(a,b) {
    return moment(a.start_time) - moment(b.start_time); 
  });
}

function after_save() {

}