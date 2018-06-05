function include_rivets_dates() {

  rivets.formatters.dayofwk    = function(val)     { return moment.parseZone(val).format('ddd')                };
  rivets.formatters.date       = function(val)     { return moment.parseZone(val).format('MMM Do')             };
  rivets.formatters.time       = function(val)     { return moment.parseZone(val).format('h:mm a')             };
  rivets.formatters.padtime    = function(val)     { return moment.parseZone(val).format('hh:mm A')            };
  rivets.formatters.fulldate   = function(val)     { return moment.parseZone(val).format('ddd MMM Do hh:mm a') };
  rivets.formatters.simpledate = function(val)     { return moment.parseZone(val).format('MM/DD/YYYY hh:mm A') }; 
  rivets.formatters.eventstart = function(val)     { return moment.parseZone(val).format('ddd M/DD hh:mm A')   };
  rivets.formatters.unmilitary = function(val)     { return moment.parseZone(val).format('h:mm A')             };
  rivets.formatters.classtime  = function(val)     { return moment.parseZone(val).format('ddd MMM D @ h:mm a') };
  rivets.formatters.unixtime   = function(val)     { return moment.parseZone(new Date(val*1000)).format('MM/DD/YYYY hh:mm A') };
  rivets.formatters.datewyr    = function(val)     { return moment.parseZone(val).format('MMM Do YYYY')        };
  
  rivets.formatters.dtrange    = function(start,end) { 
    start = moment.parseZone(start);
    end = moment.parseZone(end);
    if( start.diff(end, 'days') == 0 ) { return start.format('ddd MMM Do h:mm a') + ' - ' + end.format('h:mm a'); }
    return start.format('ddd MMM Do h:mm a') + ' - ' + end.format('ddd MMM Do h:mm a');
  }

  rivets.binders['datefield'] = { 
    bind: function(el) {
      this.flatpickrInstance = $(el).flatpickr({
        enableTime: true, 
        altInput: true, 
        altFormat: 'm/d/Y h:i K',
        onChange: function(val) { this.publish(val); if(this.el.onchange) { this.el.onchange(); } }.bind(this)
      })
    },
    routine: function(el,value) {
      if(!value) { this.flatpickrInstance.clear(); return; }
      this.flatpickrInstance.setDate( value ); 
      this.flatpickrInstance.jumpToDate(value);
    },
    getValue: function(el) { return el.value; },
    unbind:   function(el) { this.flatpickrInstance.destroy(); }
  }

  rivets.binders['timefield'] = {
    bind: function(el) {
      this.flatpickrInstance = $(el).flatpickr({
        enableTime: true, 
        altInput: true, 
        altFormat: 'h:i K',
        inline: true,
        noCalendar: true,
        onChange: function(val) { this.publish(val); if(this.el.onchange) { this.el.onchange(); } }.bind(this)
      })
    },
    routine: function(el,value) {
      if(!value) { this.flatpickrInstance.clear(); return; }
      this.flatpickrInstance.setDate( value ); 
      this.flatpickrInstance.jumpToDate(value);
    },
    getValue: function(el) { return el.value; },
    unbind:   function(el) { this.flatpickrInstance.destroy(); }
  }

  rivets.binders['daterangefield'] = {
    bind: function(el) {
      this.flatpickrInstance = $(el).flatpickr({
        mode: 'range',
        onChange: function(val) { this.publish(val); if(this.el.onchange) { this.el.onchange(); } }.bind(this)
      })
    },
    routine: function(el,value) {
      if(!value) { this.flatpickrInstance.clear(); return; }
      this.flatpickrInstance.setDate( value ); 
      this.flatpickrInstance.jumpToDate(value);
    },
    getValue: function(el) { return el.value; },
    unbind:   function(el) { this.flatpickrInstance.destroy(); }
  }

  rivets.binders['calendar'] = {
    bind: function(el) {
      this.flatpickrInstance = $(el).flatpickr({
        enableTime: false, 
        altInput: true, 
        altFormat: 'D m/d/Y',
        onChange: function(val) { this.publish(val); if(this.el.onchange) { this.el.onchange(); } }.bind(this)
      })
    },
    routine: function(el,value) {
      if(!value) { this.flatpickrInstance.clear(); return; }
      this.flatpickrInstance.setDate( value ); 
      this.flatpickrInstance.jumpToDate(value);
    },
    getValue: function(el) { return el.value; },
    unbind:   function(el) { this.flatpickrInstance.destroy(); }
  }

  rivets.binders['timefield'] = {
    bind: function(el) {
      this.flatpickrInstance = $(el).flatpickr({
        enableTime: true, 
        altInput: true, 
        altFormat: 'h:i K',
        inline: true,
        noCalendar: true,
        onChange: function(val) { this.publish(val); if(this.el.onchange) { this.el.onchange(); } }.bind(this)
      })
    },
    routine: function(el,value) {
      if(!value) { this.flatpickrInstance.clear(); return; }
      this.flatpickrInstance.setDate( value ); 
      this.flatpickrInstance.jumpToDate(value);
    },
    getValue: function(el) { return el.value; },
    unbind:   function(el) { this.flatpickrInstance.destroy(); }
  }

}
