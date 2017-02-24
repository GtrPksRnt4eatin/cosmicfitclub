ctrl = {

  add_session(e,m) {
    sessionform.show_new();
    //$.post(`/models/events/${data['event'].id}/sessions`, JSON.stringify({ id: 0 }), function(sess) {
    //  data['event']['sessions'].push(JSON.parse(sess));
    //});  
  },

  del_session(e,m) {
    $.del(`/models/events/sessions/${m.sess.id}`);
    data['event']['sessions'].splice(m.index,1);
  },

  add_price(e,m) {
    $.post(`/models/events/${data['event'].id}/prices`, JSON.stringify({ id: 0 }), function(price) {
      data['event']['prices'].push(JSON.parse(price));
    }); 
  },

  del_price(e,m) {
    $.del(`/models/events/prices/${m.price.id}`);
    data['event']['prices'].splice(m.index,1);  
  },

  choose_img(e,m) {
    
  }
	
}

$(document).ready(function() { 

  sessionform = new SessionForm();
  popupmenu   = new PopupMenu(id('popupmenu_container'));
  
  rivets.formatters.dayofwk    = function(val) { return moment(val).format('ddd') };
  rivets.formatters.date       = function(val) { return moment(val).format('MMM Do') };
  rivets.formatters.time       = function(val) { return moment(val).format('h:mm a') };
  rivets.formatters.fulldate   = function(val) { return moment(val).format('ddd MMM Do hh:mm a') };
  rivets.formatters.simpledate = function(val) { return moment(val).format('MM/DD/YYYY hh:mm A') }; 
  
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

  rivets.bind(document.body, { event: data['event'], ctrl: ctrl } );

  $('textarea').on('focus', function(e) { $(e.target).addClass('edit'); } );
  $('textarea').on('blur',  function(e) { $(e.target).removeClass('edit'); } );

  sessionform.ev_sub('show', popupmenu.show );
  sessionform.ev_sub('done', post_session);

});

function post_session(sess) {
  $.post(`/models/events/${data['event'].id}/sessions`, JSON.stringify(sess), function(sess) {
    data['event']['sessions'].push(JSON.parse(sess));
  });  
}