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
  },

  choose_img(e,m) {
    if(e.target.value) { m.class.image_url = e.target.value; }
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
  
  popupmenu = new PopupMenu( id('popupmenu_container') );

  scheduleform = new ScheduleForm();
  scheduleform.instructors = data['instructors'];
  scheduleform.ev_sub('show', popupmenu.show );
  scheduleform.ev_sub('after_post', function(schedule) { 
    data['class']['schedules'].replace_or_add_by_id(schedule); 
    popupmenu.hide();
  });

});

function initialize_rivets() {

  rivets.formatters.dayofwk    = function(val) { return moment(val).format('ddd') };
  rivets.formatters.date       = function(val) { return moment(val).format('MMM Do') };
  rivets.formatters.time       = function(val) { return moment(val).format('h:mm a') };
  rivets.formatters.fulldate   = function(val) { return moment(val).format('ddd MMM Do hh:mm a') };
  rivets.formatters.simpledate = function(val) { return moment(val).format('MM/DD/YYYY hh:mm A') };
  rivets.formatters.onlytime   = function(val) { return moment(val, ['H:m:s', 'h:m a', 'H:m'] ).format('h:mm a')};

  include_rivets_rrule();

  rivets.formatters.instructors = function(val) {
    if(empty(val)) return "null";
    return val.map( function(o) { 
      obj = data['instructors'].find( function(val) { return val.id == o; })
      return obj.name;
    })
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

  rivets.binders['timefield'] = {
    bind: function(el) {
      this.flatpickrInstance = $(el).flatpickr({
        enableTime: true, 
        altInput: true, 
        altFormat: 'h:i K',
        inline: true,
        noCalendar: true,
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
      //$(this.chosen_instance).trigger("chosen:updated");
    },
    getValue: function(el) {
      return $(this.chosen_instance).val();
    }
  }
}