function LoftCalendar(parent,attr) {

  this.selected_timeslot = attr['timeslot'];
  this.viewType = attr['view'] || "Days";
  this.admin = attr['admin'] || false;
  this.point = attr['point'] || false;
  this.floor = attr['floor'] || false;
  this.rooms = attr['rooms'] || false;
  this.theme = attr['theme'] || false;

  this.state = {
    window_start: null,
    window_end: null,
    daypilot: null,
    reservations: null,
    gcal_events: null,
    classes: null,
    loading: false,
    num_days: this.viewType=="Resources" ? 1 : 7
  }

  this.load_styles();
  this.bind_handlers(['build_daypilot', 'rebuild_daypilot', 'filter', 'on_timeslot_selected', 'get_presorted_events', 'refresh_data', 'full_refresh', 'next_wk', 'prev_wk']);
  this.build_daypilot();
  this.refresh_data();
}

LoftCalendar.prototype = {
  constructor: LoftCalendar,

  build_daypilot: function() {
    this.start = (new Date).toLocaleDateString("sv-SE");
    this.end = new Date(Date.now() + this.state.num_days*24*60*60*1000).toLocaleDateString("sv-SE");
    this.state.daypilot = new DayPilot.Calendar('daypilot', {
      viewType: this.viewType,
      theme: this.theme || null,
      days: 7,
      cellDuration: 30,
      cellHeight: 14,
      headerDateFormat: "ddd MMM d",
      headerLevels: this.viewType=="Resources" ? 2 : 1,
      columns: [
        { name: new Date(`${this.start}T00:00:00`).toLocaleDateString("en-us", { weekday: 'short', month: 'short', day: 'numeric' }), children: [
          { name: "Aerial Point", id: 'Loft-1F-Front (4)' },
          { name: "Back Room", id: 'Loft-1F-Back (8)' },
          //{ name: "Guest Rooms", children: [
          //  { name: "Rm 1", id: "Loft-1F-Guest Rm1 (2)" },
          //  { name: "Rm 2", id: "Loft-1f-GuestRm2 (2)" }
          //]}
        ]} 
      ],
      businessBeginsHour: 9,
      businessEndsHour: 24,
      dayBeginsHour: 9,
      dayEndsHour: 24,
      showAllDayEvents: true,
      eventDeleteHandling: "Disabled",
      eventMoveHandling:   "Disabled",
      eventResizeHandling: "Disabled",
      eventHoverHandling:  "Disabled",
      timeRangeSelectedHandling: (this.admin ? "Disabled" : "Enabled" ),
      eventClickHandling:        (this.admin ? "Enabled"  : "Disabled"),
      onTimeRangeSelected: this.on_timeslot_selected,
      onEventClick: this.on_reservation_selected,
      onBeforeEventRender:   function(args) {
        this.admin && ( args.data.html = args.data.text ? args.data.text.split(',').join(',<br/>') : "???" );
      }.bind(this),
      onEventFilter: function(args) {
        switch(args.e.data.resource) {
          case 'Loft-1F-Front (4)':     if(!this.point) { args.visible = false; } break;
          case 'Loft-1F-Back (8)':      if(!this.floor) { args.visible = false; } break;
          case 'Loft-1F-Guest Rm1 (2)':
          case 'Loft-1F-GuestRm2 (2)': 
          case 'Loft-1F-Futon (1)':     if(!this.rooms) { args.visible = false; } break;
          default:
            console.log(args.e.data);
            args.visible = false;
        }
      }.bind(this),
    });
    this.state.daypilot.init();
    this.filter();
  },

  filter: function() {
    this.state.daypilot.events.filter("asdf");
  },

  get_presorted_events: function() {
    return $.get( `/models/schedule/loft_calendar/${this.start}/${this.end}${this.admin ? '?admin=true' : ''}`)
     .then(function(resp) {
       this.state.events = resp;
       this.state.daypilot.events.list = [];
       this.state.events.for_each( function(event) {
         this.state.daypilot.events.add({ ...event, backColor: event.resource == 'Loft-1F-Front (4)' ? '#EEEEFF' : '#FFEEEE' })
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
    if(!this.silent) this.loading = true;
    return this.get_presorted_events().then(this.rebuild_daypilot()).then(function() { this.loading = false; }.bind(this))
  },

  rebuild_daypilot: function() {
    this.state.daypilot.startDate = this.start;
    this.state.daypilot.columns.list[0].name = new Date(`${this.start}T00:00:00`).toLocaleDateString("en-us", { weekday: 'short', month: 'short', day: 'numeric' });
    this.state.daypilot.update();
  },

  full_refresh: function(silent=false) {
    this.silent = silent;
    let date = new Date;
    this.start = date.toLocaleDateString("sv-SE");
    date.setDate(date.getDate() + this.state.num_days);
    this.end = date.toLocaleDateString("sv-SE");
    this.refresh_data()
  },

  next_wk: function() {
    let date = new Date(this.start+"T00:00:00")
    date.setDate(date.getDate() + this.state.num_days);
    this.start = date.toLocaleDateString("sv-SE");
    date.setDate(date.getDate() + this.state.num_days);
    this.end = date.toLocaleDateString("sv-SE");
    this.refresh_data();
  },

  prev_wk: function() {
    let date = new Date(this.end+"T00:00:00")
    date.setDate(date.getDate() - this.state.num_days);
    this.end = date.toLocaleDateString("sv-SE");
    date.setDate(date.getDate() - this.state.num_days);
    this.start = date.toLocaleDateString("sv-SE");
    this.refresh_data();
  }
}

Object.assign( LoftCalendar.prototype, element);
Object.assign( LoftCalendar.prototype, ev_channel);

LoftCalendar.prototype.HTML = `

  <div class='loftcalendar'>
    <button rv-on-click='prev_wk'>Prev</button>
    <button rv-on-click='next_wk'>Next</button>
    <input type="checkbox" rv-checked='point' rv-on-change='filter'/>
    <input type="checkbox" rv-checked='floor' rv-on-change='filter'/>
    <input type="checkbox" rv-checked='rooms' rv-on-change='filter'/>
    <div id='daypilot'></div>
    <div class='mask' rv-if='loading'>Loading...</div>
  </div>

`.untab(2);

LoftCalendar.prototype.CSS = `

  loft-calendar {
    line-height: 1em;
    position: relative
  }

  .loftcalendar {
    position: relative;
  }
  
  loft-calendar .calendar_default_event_inner {
    font-size: 10px;
    line-height: 1.2em;
    padding: 8px 2px 2px 6px
  }

  loft-calendar .mask {
    background: rgba(0, 0, 0, 0.8);
    position: absolute;
    left: 0; right: 0;
    top: 0;  bottom: 0;
    display: flex;
    font-size: 3.5em;
    align-items: center;
    justify-content: center;
    box-shadow: 0 0 2em white inset;
    animation: 1s infinite alternate loading
  }b

  @keyframes loading {
    from { box-shadow: 0 0 1em white inset; }
    to   { box-shadow: 0 0 2em white inset; }
  }

`.untab(2);

rivets.components['loft-calendar'] = { 
  static: ['admin','view', 'theme', 'point', 'floor', 'rooms'],
  template:   function()        { return LoftCalendar.prototype.HTML; },
  initialize: function(el,attr) { return new LoftCalendar(el,attr);   }
}