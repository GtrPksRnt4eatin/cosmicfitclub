function SessionChooser(parent,attr) {

  this.event      = attr['event'];
  this.session    = attr['session'];
  this.attendance = attr['attendance'];
  this.passes     = attr['passes']
  
  this.state = {
    sessions: [],
    included_sessions: []
  }
  
  this.bind_handlers(['build_daypilot','load_sessions','get_attendance','update_daypilot_colors','session_available','on_session_selected','sort_included_sessions','set_included_sessions','clear_session']);
  this.load_styles();
}
  
  SessionChooser.prototype = {
      constructor: SessionChooser,
  
      build_daypilot: function() {
        //this.daypilot && this.daypilot.dispose();
        let start_of_day = Math.min(...this.event.sessions.map(function(x) { return new Date(x.start_time).getHours(); })) - 1;
        let end_of_day = Math.max(...this.event.sessions.map(function(x) { return new Date(x.end_time).getHours(); })) + 1;
        
        this.daypilot = new DayPilot.Calendar("daypilot", {
          headerDateFormat:          "ddd MMM d",
          startDate:                 moment(this.event.starttime).format("YYYY-MM-DD"),       
          days:                      moment(this.event.endtime).endOf('day').diff(moment(this.event.starttime).startOf('day'),"days")+1,
          cellDuration:              30,
          cellHeight:                20,
          businessBeginsHour:        start_of_day,
          businessEndsHour:          end_of_day,
          dayBeginsHour:             start_of_day,
          dayEndsHour:               end_of_day,
          viewType:                  "Days",
          timeRangeSelectedHandling: "Disabled",  
          eventMoveHandling:         "Disabled",
          eventResizeHandling:       "Disabled",
          eventHoverHandling:        "Disabled",
          eventClickHandling:        "Select",
          onEventClick:              this.on_session_selected,
        });
        this.daypilot.init();
      },
  
      load_sessions: function(sessions) {
        list = sessions || this.event.sessions;
        list && list.for_each( function(sess) {
          this.daypilot.events.add({
            id:    sess.id, 
            start: moment(sess.start_time).tz('America/New_York').format('YYYY-MM-DDTHH:mm:ss'), 
            end:   moment(sess.end_time).tz('America/New_York').format('YYYY-MM-DDTHH:mm:ss'), 
            text:  (sess.title == "Private") ? sess.title : (sess.title + "\r\n" + rivets.formatters.money(sess.individual_price_full))
          })
        }.bind(this));
      },
  
      get_attendance: function() {
        $.get("/models/events/" + this.event.id + "/attendance2")
         .success( function(val) { 
            this.state.attendance = val;
            this.update_daypilot_colors();
          }.bind(this))
      },
  
      update_daypilot_colors() {
        this.daypilot.events.all().for_each( function(x) {
          let session    = this.event.sessions.find(   function(y) { return x.id() == y.id;        } );
          let attendance = this.attendance.find(       function(z) { return x.id() == z.id;        } );
          let passes     = this.passes.find(           function(q) { return x.id() == q.session_id } );
          if( !attendance || !session ) return;
              
          if(session.title == "Private") {
            x.text(session.title);
          }
          else {
            x.text(session.title + "\r\n" + rivets.formatters.money(session.individual_price_full) + "\r\n" + attendance.passes.length + "/" + session.max_capacity);
          }
          
  
          let full     = attendance.passes.length >= session.max_capacity || ( session.title == "Private" && attendance.passes.length > 0 );
          let selected = !!passes
  
          x.client.backColor( full ? "#AAAAAA" : selected ? "#CCCCFF" : "#FFFFFF" );
  
          this.daypilot.events.update(x);
        }.bind(this));
      },
  
  
      session_available(id) {
        let session    = this.event.sessions.find(   function(y) { return id == y.id; } );
        let attendance = this.attendance.find(       function(z) { return id == z.id; } );
        if( !attendance || !session ) return false;
        if( attendance.passes.length >= session.max_capacity || ( session.title == "Private" && attendance.passes.length > 0 ) ) return false;
        return true;
      },
  
      on_session_selected: function(args) {
          if(args.originalEvent.type=='touchend') { return; }
          if(!userview.logged_in) { userview.onboard(); return;  }
          if( !this.session_available(args.e.data.id) ) { return; }
  
          this.session = this.event.sessions.find( function(x) { return args.e.data.id == x.id; });
          
          let atten = this.attendance.find( function(z) { return this.session.id == z.id; }.bind(this) );
          this.session.available_slots = atten ? this.session.max_capacity - atten.passes.length : this.session.max_capacity;

          this.ev_fire('on_session_selected', this.session);
      },
  
      sort_included_sessions() {
        this.state.included_sessions.sort( function(a,b) { 
          let sess_a = this.event.sessions.find( function(x) { return x.id == a; } );
          let sess_b = this.event.sessions.find( function(x) { return x.id == b; } );
          if(!sess_a) { return sess_b ? 1 : 0; }
          if(!sess_b) { return sess_a ? -1 : 0; }
          return moment(sess_a.start_time) - moment(sess_b.start_time);
        });
      },
  
      clear_session() {
        this.state.selected_session = null;
      }
  }
  
  Object.assign( SessionChooser.prototype, element);
  Object.assign( SessionChooser.prototype, ev_channel);
  
  SessionChooser.prototype.HTML = `
    <div>  
      <hr class='mobile'><br class='mobile'>    
      <h2>Choose An Available Session:</h2><br/>
      <div id='daypilot'></div>
    </div>  
  `.untab(2);
  
  SessionChooser.prototype.CSS = `
    session-chooser #daypilot {
      border: 0.5em solid rgba(255,255,255,0.5);
    }
  `.untab(2);
  
  rivets.components['session-chooser'] = { 
    template:   function()        { return SessionChooser.prototype.HTML; },
    initialize: function(el,attr) { return new SessionChooser(el,attr);   }
  }
