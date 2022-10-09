function LoftCalendar(parent,attr) {

  this.selected_timeslot = attr['timeslot']

	this.state = {
      window_start: null,
      window_end: null,
      daypilot: null,
      reservations: null   
	}

	this.bind_handlers(['build_daypilot', 'on_timeslot_selected']);
  this.build_daypilot();

}

LoftCalendar.prototype = {
  constructor: LoftCalendar,

  build_daypilot: function() {
    this.state.daypilot = new DayPilot.Calendar('daypilot', {
      viewType: "Week",
      cellDuration: 30,
      cellHeight: 20,
      headerDateFormat: "ddd MMM d",
      businessBeginsHour: 9,
      businessEndsHour: 24,
      dayBeginsHour: 9,
      dayEndsHour: 24,
      timeRangeSelectedHandling: "Enabled",
      onTimeRangeSelected: this.on_timeslot_selected,
      eventDeleteHandling: "Disabled",
      eventMoveHandling: "Disabled",
      eventResizeHandling: "Disabled",
      eventClickHandling: "Disabled",
      eventHoverHandling: "Disabled",
    });
    this.state.daypilot.init();
  },

  get_reservations: function(from,to) {
    $.get( '/models/groups/range', { from: from, to: to } )
     .then( 
       function(resp) { this.state.reservations = resp; }.bind(this) 
     );
  },

  on_timeslot_selected: function(args) {
    this.ev_fire('on_timeslot_selected', args);
  }

}

Object.assign( LoftCalendar.prototype, element);
Object.assign( LoftCalendar.prototype, ev_channel);

LoftCalendar.prototype.HTML = `
  <div class='loftcalendar'>
    <div id='daypilot'></div>
  </div>
`.untab(2);

LoftCalendar.prototype.CSS = `
  
  .loftcalendar {

  }

`.untab(2);

rivets.components['loft-calendar'] = { 
  template:   function()        { return LoftCalendar.prototype.HTML; },
  initialize: function(el,attr) { return new LoftCalendar(el,attr);   }
}