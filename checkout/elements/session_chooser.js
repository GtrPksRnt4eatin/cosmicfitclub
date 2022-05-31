function SessionChooser(parent,attr) {

  this.event      = attr['event'];
  this.attendance = attr['attendance'];
  
  this.state = {
    sessions: [],
    attendance: [],
    included_sessions: []
  }
  
  this.bind_handlers(['build_daypilot','load_sessions','get_attendance','update_daypilot_colors','session_available','on_session_selected','sort_included_sessions','set_included_sessions','toggle_included_sessions','clear_session']);

  //setTimeout(function() {
    //this.build_daypilot();
    //this.load_sessions();
    //this.get_attendance();
  //}.bind(this),0)

}
  
  SessionChooser.prototype = {
      constructor: SessionChooser,
  
      build_daypilot: function() {
        //this.daypilot && this.daypilot.dispose();
        this.daypilot = new DayPilot.Calendar("daypilot", {
          headerDateFormat:          "ddd MMM d",
          startDate:                 moment(this.event.starttime).format("YYYY-MM-DD"),       
          days:                      moment(this.event.endtime).diff(moment(this.event.starttime),"days")+1,
          cellDuration:              30,
          cellHeight:                20,
          businessBeginsHour:        10,
          businessEndsHour:          20,
          dayBeginsHour:             10,
          dayEndsHour:               20,
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
            start: moment(sess.start_time).subtract(4,'hours').format(), 
            end:   moment(sess.end_time).subtract(4,'hours').format(), 
            text:  sess.title + "\r\n" + rivets.formatters.money(sess.individual_price_full)
          })
        }.bind(this));
        this.update_daypilot_colors();
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
          let session    = this.event.sessions.find(   function(y) { return x.id() == y.id; } );
          let attendance = this.attendance.find(       function(z) { return x.id() == z.id; } );
          if( !attendance || !session ) return;
              
          if(session.title != "Private") {
            x.text(session.title + "\r\n" + rivets.formatters.money(session.individual_price_full) + "\r\n" + attendance.passes.length + "/" + session.max_capacity);
          }
  
          let full     = attendance.passes.length >= session.max_capacity || ( session.title == "Private" && attendance.passes.length > 0 );
          let selected = data.included_sessions.includes(x.id());
  
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
  
          this.state.selected_session = this.event.sessions.find( function(x) { return args.e.data.id == x.id; });
          //this.toggle_included_session(args.e.data);
          //this.update_daypilot_colors();
          this.ev_fire('on_session_selected', this.state.selected_session);
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
      
      set_included_sessions(sessions) {
        for(var i=0; i < this.event.sessions.length; i++) { 
          this.event.sessions[i].selected = sessions.indexOf(this.event.sessions[i].id)!=-1;
        }
        this.state.included_sessions = sessions.slice(0);
        sort_included_sessions();
      },
      
      toggle_included_session(session) {
        sessions = this.state.included_sessions;
        var i = sessions.indexOf(session.id);
        if(i==-1) { sessions.push(session.id); this.state.num_slots=1; }
        else { 
          if(sessions.length == 1) { sessions = []; }
          else { sessions.splice(i, 1); }
        }
        set_included_sessions(sessions);
      },
  
      clear_session() {
        this.state.selected_session = null;
      }
  }
  
  Object.assign( SessionChooser.prototype, element);
  Object.assign( SessionChooser.prototype, ev_channel);
  
  SessionChooser.prototype.HTML = ES5Template(function(){/**
    <div rv-hide='state.selected_session'>  
      <hr class='mobile'><br class='mobile'>    
      <h2>Choose An Available Session:</h2><br/>
      <div id='daypilot'></div>
    </div>  
  **/}).untab(2);
  
  SessionChooser.prototype.CSS = `
  
  `.untab(2);
  
  rivets.components['session-chooser'] = { 
    template:   function()        { return SessionChooser.prototype.HTML; },
    initialize: function(el,attr) { return new SessionChooser(el,attr);   }
  }