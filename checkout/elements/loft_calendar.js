function LoftCalendar(parent) {

	this.state = {
      window_start: null,
      window_end: null,
      daypilot: null,
      reservations: null   
	}

	this.bind_handlers(['build_daypilot']);
	this.build_dom(parent);
	this.load_styles();
	this.bind_dom();

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

  on_timeslot_seleted: function(args) {
    console.log(args);
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