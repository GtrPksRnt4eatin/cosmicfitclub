function LoftCalendar(parent,attr) {

  this.selected_timeslot = attr['timeslot'];
  this.admin = attr['admin'];
  this.viewType = attr['view'] || "Days";

  this.state = {
    window_start: null,
    window_end: null,
    daypilot: null,
    reservations: null,
    gcal_events: null,
    classes: null,
    loading: false,
    point: true,
    floor: false,
    rooms: false,
    num_days: this.viewType=="Resources" ? 1 : 7
  }
      
  this.start = (new Date).toISOString().split('T')[0];
  this.end = new Date(Date.now() + this.state.num_days*24*60*60*1000).toISOString().split('T')[0];
  
  this.load_styles();
  this.bind_handlers(['build_daypilot', 'filter', 'on_timeslot_selected', 'get_reservations', 'get_gcal_events', 'refresh_data', 'full_refresh', 'next_wk', 'prev_wk']);
  this.build_daypilot();
  this.refresh_data();
}

LoftCalendar.prototype = {
  constructor: LoftCalendar,

  build_daypilot: function() {
    this.state.daypilot = new DayPilot.Calendar('daypilot', {
      viewType: this.viewType,
      days: 7,
      cellDuration: 30,
      cellHeight: 14,
      headerDateFormat: "ddd MMM d",
      headerLevels: this.viewType=="Resources" ? 3 : 1,
      columns: [
        { name: new Date(this.start).toLocaleDateString("en-us", { weekday: 'short', month: 'short', day: 'numeric' }), children: [
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
      showAllDayEvents: false,
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
          case 'Loft-1F-Front (4)':
            if(!this.state.point) { args.visible = false; }
            break;
          case 'Loft-1F-Back (8)':
            if(!this.state.floor) { args.visible = false; }
            break;
          case 'Loft-1F-Guest Rm1 (2)':
          case 'Loft-1F-GuestRm2 (2)':
            if(!this.state.rooms) { args.visible = false; }
            break;
          default:
            console.log(args.e.data.text);
            console.log(args.e.data);
            console.log(args.e.resource());
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

  get_classes: function() {
    return $.get(`/models/schedule/${this.start}/${this.end}`)
     .then(function(resp) {
       this.state.classes = resp;
       this.state.classes.for_each( function(cls) {
         if(cls["location_id"] != 2) { return; }
         let dst_hrs = moment(cls["starttime"]).isDST() ? 4 : 5; 
         location && this.state.daypilot.events.add({
           id: cls["sched_id"],
           start: moment(cls["starttime"]).subtract(dst_hrs,'hours').format(),
           end: moment(cls["endtime"]).subtract(dst_hrs,'hours').format(),
           text: cls["classdef"]["name"],
           resource: "Loft-1F-Back (8)",
           data: { resource: "Loft-1F-Back (8)" },
           allday: false,
           backColor: '#EEEEFF'
         })
       })
       console.log('Class Items:');
       console.log(resp);
     }.bind(this));
  },

  get_reservations: function() {
    let path = this.admin ? `/models/groups/range-admin/${this.start}/${this.end}` : `/models/groups/range/${this.start}/${this.end}`
    return $.get( path )
     .then(function(resp) { 
        this.state.reservations = resp;
        this.state.reservations.for_each( function(res) {
          let gcal = this.state.daypilot.events.find(res.gcal);
          if(gcal) {
            console.log('replacing:'); 
            console.log(gcal);
            console.log(res);
            let resource = gcal.resource(); 
            this.state.daypilot.events.remove(gcal);
            res.data ||= {};
            res.data.resource = resource;
            res.resource = resource;
          }
          this.state.daypilot.events.add(res);
        }.bind(this))
      }.bind(this));
  },

  get_gcal_events: function() {
    return $.get( '/models/schedule/loft_events')
     .then(function(resp) { 
        this.state.gcal_events = resp;
        this.state.gcal_events.for_each( function(event) {
          //if(event.location != "Loft-1F-Front (4)") return;
          let dst_hrs = moment(event.start).isDST() ? 4 : 5; 
          location && this.state.daypilot.events.add({
            id: event.gcal_id,
            start: moment(event.start).subtract(dst_hrs,'hours').format(),
            end: moment(event.end).subtract(dst_hrs,'hours').format(),
            text: this.admin ? event.summary : "Reserved",
            resource: event.location,
            data: { resource: event.location },
            allday: event.allday,
            backColor: '#EEEEFF'
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
    return this.get_gcal_events()
      .then(function() { return this.get_reservations()      }.bind(this))
      .then(function() { return this.get_classes()           }.bind(this))
      .then(function() { return this.state.daypilot.update() }.bind(this))
      .then(function() { this.loading = false;               }.bind(this))
  },

  full_refresh: function() {
    this.start = (new Date).toLocaleDateString('en-CA');
    this.end = new Date(Date.now() + 7*24*60*60*1000).toLocaleDateString('en-CA');
    this.refresh_data().then( function() {
      this.state.daypilot.startDate = this.start;
      this.state.daypilot.update();
    }.bind(this) );
  },

  next_wk: function() {
    let date = new Date(this.start+"T00:00:00")
    date.setDate(date.getDate() + this.state.num_days);
    this.start = date.toISOString().split('T')[0];
    date.setDate(date.getDate() + this.state.num_days);
    this.end = date.toISOString().split('T')[0];
    this.refresh_data().then( function() {
      this.state.daypilot.startDate = this.start;
      this.state.daypilot.columns.list[0].name = new Date(this.start).toLocaleDateString("en-us", { weekday: 'short', month: 'short', day: 'numeric' });
      this.state.daypilot.update();
    }.bind(this) );
  },

  prev_wk: function() {
    let date = new Date(this.start+"T00:00:00")
    date.setDate(date.getDate() - this.state.num_days);
    this.start = date.toISOString().split('T')[0];
    date.setDate(date.getDate() - this.state.num_days);
    this.end = date.toISOString().split('T')[0];
    this.refresh_data().then( function() {
      this.state.daypilot.startDate = this.start;
      this.state.daypilot.columns.list[0].name = new Date(this.start).toLocaleDateString("en-us", { weekday: 'short', month: 'short', day: 'numeric' });
      this.state.daypilot.update();
    }.bind(this) );
  }
}

Object.assign( LoftCalendar.prototype, element);
Object.assign( LoftCalendar.prototype, ev_channel);

LoftCalendar.prototype.HTML = `

  <div class='loftcalendar'>
    <button rv-on-click='prev_wk'>Prev</button>
    <button rv-on-click='next_wk'>Next</button>
    <input type="checkbox" rv-checked='state.point' rv-on-change='filter'/>
    <input type="checkbox" rv-checked='state.floor' rv-on-change='filter'/>
    <input type="checkbox" rv-checked='state.rooms' rv-on-change='filter'/>
    <div id='daypilot'></div>
  </div>

`.untab(2);

LoftCalendar.prototype.CSS = `
  
  loft-calendar .calendar_default_event_inner {
    font-size: 10px;
    line-height: 1.2em;
    padding: 8px 2px 2px 6px
  }

`.untab(2);

rivets.components['loft-calendar'] = { 
  static: ['admin','view'],
  template:   function()        { return LoftCalendar.prototype.HTML; },
  initialize: function(el,attr) { return new LoftCalendar(el,attr);   }
}
