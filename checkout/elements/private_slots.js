function PrivateSlots(parent,attr) {

  this.event = attr['event'];

	this.state = {
      sessions: [],
      starttime: null,
      endtime: null,
      page: 0
	}

	this.bind_handlers(['build_daypilot','load_sessions','get_attendance','update_daypilot_colors','on_session_selected']);
	this.load_styles();
	//this.bind_dom();

  this.build_daypilot();
  this.get_attendance();
}

PrivateSlots.prototype = {
	constructor: PrivateSlots,

    build_daypilot: function() {
        this.daypilot = new DayPilot.Calendar("daypilot", {
            headerDateFormat:          "ddd MMM d",
            startDate:                 moment(state.starttime).format("YYYY-MM-DD"),       
            days:                      moment(state.endtime).diff(moment(state.starttime),"days")+1,
            cellDuration:              30,
            cellHeight:                20,
            businessBeginsHour:        10,
            businessEndsHour:          20,
            dayBeginsHour:             10,
            dayEndsHour:               20,
            viewType:                  "Days",
            timeRangeSelectedHandling: "Disabled",  
            eventDeleteHandling:       "Disabled",
            eventMoveHandling:         "Disabled",
            eventResizeHandling:       "Disabled",
            eventHoverHandling:        "Disabled",
            eventClickHandling:        "Select",
            onEventClick:              this.on_session_selected,
        });
    },

    load_sessions: function(sessions) {
        list = sessions || this.event.sessions;
        list.for_each( function(sess) {
            this.daypilot.events.add({
                id:    x.id, 
                start: moment(x.start_time).subtract(4,'hours').format(), 
                end:   moment(x.end_time).subtract(4,'hours').format(), 
                text:  x.title + "\r\n" + rivets.formatters.money(x.individual_price_full)
            })
        });
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
            let session    = this.event.sessions.find( function(y) { return x.id() == y.id; } );
            let attendance = this.attendance.find(     function(z) { return x.id() == z.id; } );
            if( !attendance || !session ) return;
            
            if(session.title != "Private") {
              x.text(session.title + "\r\n" + rivets.formatters.money(session.individual_price_full) + "\r\n" + attendance.passes.length + "/" + session.max_capacity);
            }
            if(attendance.passes.length >= session.max_capacity || ( session.title == "Private" && attendance.passes.length > 0 ) ) {
              x.client.backColor("#AAAAAA");
            }
            else if( data.included_sessions.includes(x.id()) ) {
              x.client.backColor("#CCCCFF");
            }
            else {
              x.client.backColor("#FFFFFF");
            }
            daypilot.events.update(x);
        });
    },

    on_session_selected: function() {
        if(args.originalEvent.type=='touchend') { return; }
        if(!userview.logged_in) { userview.onboard(); return;  }
        if( !session_available(args.e.data.id) ) { return; }
      
        clear_selected_price();
        toggle_included_session(args.e.data);
        calculate_custom_prices();
        calculate_total();
        this.update_daypilot_colors();
    }
}

Object.assign( PrivateSlots.prototype, element);
Object.assign( PrivateSlots.prototype, ev_channel);

PrivateSlots.prototype.HTML = ES5Template(function(){/**
  <div id='private_slots'>
    <div rv-show='state.page | equals 0'>  
      <hr class='mobile'>
      <br class='mobile'>
      
      <h2>Choose An Available Session:</h2>
      <br>

      <div id='daypilot'></div>
    </div>

  </div>
**/}).untab(2);

PrivateSlots.prototype.CSS = `

`.untab(2);

rivets.components['private-slots'] = { 
  template:   function()        { return PrivateSlots.prototype.HTML; },
  initialize: function(el,attr) { return new PrivateSlots(el,attr);   }
}