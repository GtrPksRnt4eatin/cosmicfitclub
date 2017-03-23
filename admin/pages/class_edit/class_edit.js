ctrl = {

  save_changes(e,m) {
    
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

  rivets.binders['multiselect'] = {
    bind: function(el) {
      this.chosen_instance = $(el).chosen()
      this.chosen_instance.change(function(val) {
        this.publish(val);
        if(this.el.onchange) { this.el.onchange(); }
      }.bind(this));
    },
    unbind: function(el) {
      $(el).chosen("destroy");
    },
    routine: function(el,value) {
      $(el).val(value);
      $(this.chosen_instance).trigger("chosen:updated");
    },
    getValue: function(el) {
      return $(this.chosen_instance).val();
    }

  }

  rivets.bind($('#content'), { data: data, class: data['class'], ctrl: ctrl } );

  $('textarea').on('focus', function(e) { $(e.target).addClass('edit'); } );
  $('textarea').on('blur',  function(e) { $(e.target).removeClass('edit'); } );

});