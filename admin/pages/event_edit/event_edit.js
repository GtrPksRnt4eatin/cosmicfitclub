ctrl = {

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
  
  rivets.formatters.dayofwk    = function(val) { return moment(val).format('ddd') };
  rivets.formatters.date       = function(val) { return moment(val).format('MMM Do') };
  rivets.formatters.time       = function(val) { return moment(val).format('h:mm a') };
  rivets.formatters.fulldate   = function(val) { return moment(val).format('ddd MMM Do hh:mm a') };
  rivets.formatters.simpledate = function(val) { return moment(val).format('MM/DD/YYYY hh:mm A') }; 

  rivets.formatters.session_names = function(arr) {
    if(empty(arr)) return arr;
    return arr.map(function(id) {
      var sess = data.event.sessions.find( function(sess) { return sess.id == id } )
      return ( sess && sess.title );
    }).join(',');
  }
  
  rivets.binders['datefield'] = {
    bind: function(el) {
      this.flatpickrInstance = $(el).flatpickr({
        enableTime: true, 
        altInput: true, 
        altFormat: 'm/d/Y h:i K',
        onChange: function(val) {
          this.publish(val);
          if(this.el.onchange) { this.el.onchange(); }
        }.bind(this)
      })
    },
    unbind: function(el) {
      this.flatpickrInstance.destroy();
    },
    routine: function(el,value) {
      if(value) { 
        this.flatpickrInstance.setDate( value ); 
        this.flatpickrInstance.jumpToDate(value);
      }
    },
    getValue: function(el) {
      return el.value;
    }
  }

  rivets.bind($('#content'), { event: data['event'], ctrl: ctrl } );

  popupmenu   = new PopupMenu(id('popupmenu_container'));

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

  id("pic").onchange = function () {
    var reader = new FileReader();
    reader.onload = function (e) { id("picpreview").src = e.target.result; };
    reader.readAsDataURL(this.files[0]);
  };

  sortSessions();

});

function sortSessions() {
  data['event']['sessions'].sort( function(a,b) {
    return moment(a.start_time) - moment(b.start_time); 
  });
}

function after_save() {

}