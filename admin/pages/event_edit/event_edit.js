ctrl = {

  add_session(e,m) { sessionform.show_new(); cancelEvent(e); },
  add_price(e,m)   { priceform.show_new();   cancelEvent(e); },

  edit_session(e,m) { sessionform.show_edit(m.sess); cancelEvent(e); },
  edit_price(e,m)   { priceform.show_edit(m.price);  cancelEvent(e); },

  del_session(e,m) {
    $.del(`/models/events/sessions/${m.sess.id}`)
      .done( function() { data['event']['sessions'].splice(m.index,1); } );
  },

  del_price(e,m) {
    $.del(`/models/events/prices/${m.price.id}`)
      .done( function() { data['event']['prices'].splice(m.index,1); } ); 
  },

  choose_img(e,m) {
    
  }
	
}

$(document).ready(function() { 
  
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

  rivets.bind($('#content'), { event: data['event'], ctrl: ctrl } );

  $('textarea').on('focus', function(e) { $(e.target).addClass('edit'); } );
  $('textarea').on('blur',  function(e) { $(e.target).removeClass('edit'); } );

  popupmenu   = new PopupMenu(id('popupmenu_container'));
  sessionform = new SessionForm();
  priceform   = new PriceForm();

  sessionform.ev_sub('show', popupmenu.show );
  priceform.ev_sub('show',   popupmenu.show );

  priceform.ev_sub('after_post', function(price) {
    var i = data['event']['prices'].findIndex( function(obj) { obj['id'] == price['id']; });
    if(i != -1) { data['event']['prices'][i] = price;  }
    else        { data['event']['prices'].push(price); }
    popupmenu.hide();
  });

  sessionform.ev_sub('after_post', function(sess) {
    var i = data['event']['sessions'].findIndex( function(obj) { obj['id'] == sess['id']; });
    if(i != -1) { data['event']['sessions'][i] = sess;  }
    else        { data['event']['sessions'].push(sess); }
    popupmenu.hide();
  });

});