function LoftCalendar(parent,attr) {

  this.selected_timeslot = attr['timeslot'];
  this.admin = attr['admin'];

  this.state = {
    window_start: null,
    window_end: null,
    daypilot: null,
    reservations: null,
    gcal_events: null,
    loading: false   
  }
      
  this.start = (new Date).toISOString().split('T')[0];
  this.end = new Date(Date.now() + 7*24*60*60*1000).toISOString().split('T')[0];
  
  this.bind_handlers(['build_daypilot', 'on_timeslot_selected', 'get_reservations', 'get_gcal_events', 'refresh_data', 'next_wk', 'prev_wk']);
  this.build_daypilot();
  this.refresh_data();
}

LoftCalendar.prototype = {
  constructor: LoftCalendar,

  build_daypilot: function() {
    this.state.daypilot = new DayPilot.Calendar('daypilot', {
      viewType: "Days",
      days: 7,
      cellDuration: 30,
      cellHeight: 20,
      headerDateFormat: "ddd MMM d",
      businessBeginsHour: 9,
      businessEndsHour: 24,
      dayBeginsHour: 9,
      dayEndsHour: 24,
      showAllDayEvents: false,
      eventDeleteHandling: "Disabled",
      eventMoveHandling: "Disabled",
      eventResizeHandling: "Disabled",
      eventHoverHandling: "Disabled",
      timeRangeSelectedHandling: (this.admin ? "Disabled" : "Enabled"),
      eventClickHandling: (this.admin ? "Enabled" : "Disabled"),
      onTimeRangeSelected: this.on_timeslot_selected,
      onEventClick: this.on_reservation_selected,
      onBeforeEventRender:   function(args) {
        this.admin && ( args.data.html = args.data.text.split(',').join(',<br/>'));
      },
    });
    this.state.daypilot.init();
  },

  get_reservations: function() {
    let path = this.admin ? `/models/groups/range-admin/${this.start}/${this.end}` : `/models/groups/range/${this.start}/${this.end}`
    return $.get( path )
     .then(function(resp) { 
        this.state.reservations = resp;
        this.state.reservations.for_each( function(res) {
          this.state.daypilot.events.add(res);
        }.bind(this))
      }.bind(this));
  },

  get_gcal_events: function() {
    return $.get( '/models/schedule/loft_events')
     .then(function(resp) { 
        this.state.gcal_events = resp;
        this.state.gcal_events.for_each( function(event) {
          if(event.location != "Loft-1F-Front (4)") return;
          location && this.state.daypilot.events.add({
            id: 12345,
            start: moment(event.start).subtract(4,'hours').format(),
            end: moment(event.end).subtract(4,'hours').format(),
            text: this.admin ? event.summary : "Reserved", 
            allday: event.allday,
            backColor: '#DDDDFF'
          })
        }.bind(this)) 
      }.bind(this));
  },

  on_timeslot_selected: function(args) {
    this.ev_fire('on_timeslot_selected', args);
  },

  on_reservation_selected: function(args) {
    if(args.e.data.id==12345) { alert("Google Calendar Events Can't be opened here"); return; }
    window.location = '/checkout/group/' + args.e.data.id;
  },

  refresh_data: function() {
    if(this.loading) return;
    this.loading = true;
    this.state.daypilot.events.list = [];
    this.get_reservations()
      .then(function() { return this.get_gcal_events()       }.bind(this))
      .then(function() { return this.state.daypilot.update() }.bind(this))
      .then(function() { this.state.loading = false;         }.bind(this))
  },

  next_wk: function() {
    let date = new Date(this.start+"T00:00:00")
    date.setDate(date.getDate() + 7);
    this.start = date.toISOString().split('T')[0];
    date.setDate(date.getDate() + 7);
    this.end = date.toISOString().split('T')[0];
    this.refresh_data();
  },

  prev_wk: function() {
    let date = new Date(this.start+"T00:00:00")
    date.setDate(date.getDate() - 7);
    this.start = date.toISOString().split('T')[0];
    date.setDate(date.getDate() - 7);
    this.end = date.toISOString().split('T')[0];
    this.refresh_data();
  }
}

Object.assign( LoftCalendar.prototype, element);
Object.assign( LoftCalendar.prototype, ev_channel);

LoftCalendar.prototype.HTML = `
  <div class='loftcalendar'>
    <button rv-on-click='prev_wk'>Prev</button>
    <button rv-on-click='next_wk'>Next</button>
    <div id='daypilot'></div>
  </div>
`.untab(2);

LoftCalendar.prototype.CSS = `
  
  .loftcalendar {

  }

`.untab(2);

rivets.components['loft-calendar'] = { 
  static: ['admin'],
  template:   function()        { return LoftCalendar.prototype.HTML; },
  initialize: function(el,attr) { return new LoftCalendar(el,attr);   }
}
