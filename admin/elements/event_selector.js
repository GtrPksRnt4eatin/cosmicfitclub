function EventSelector(el, attr) {
  this.dom = el;

  this.state = {
    events: [],
    event_id: null,
    callback: attr && attr['callback']
  }

  this.bind_handlers(['fetch_events', 'init_selectize', 'show', 'select_event', 'event_selected']);
  this.build_dom();
  this.bind_dom();
  this.load_styles();
  this.fetch_events();
}
  
EventSelector.prototype = {
  constructor: EventSelector,

  fetch_events() {
    $.get('/models/events/list', function(val) { 
      this.state.events = val.map(function(x) { 
        let start = moment.parseZone(x.starttime).format('ddd MMM Do YYYY');
        return { 
          label: `${start} [${x.id}] ${x.title}`,
          ...x
        } 
      }); 
      this.init_selectize();
      //this.selectize = $('select', this.dom).selectize({
      //  onChange: function(val) {
      //    this.state.callback && this.state.callback(val);
      //  }.bind(this)
      //});
      //this.selectize.on( 'click', function () {
      //  this.selectize.selectize.clear(false);
      //  this.selectize.selectize.focus();
      //}.bind(this));
    }.bind(this) );
  },

  init_selectize: function() {
    var el = $(this.dom).find('select.events');
    this.selectize_instance = el.selectize({
      options: this.state.events,
      valueField: 'id',
      labelField: 'list_string',
      searchField: 'list_string',
      openOnFocus: false
    })[0];
    $(el).next().on( 'click', function () {
      this.selectize_instance.selectize.clear(false);
      this.selectize_instance.selectize.focus();
    }.bind(this));
  },

  show: function(value, callback) {
	  this.state.event_id = value;
	  this.state.callback = callback;
    this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} );
	},

  select_event: function(event_id, silent) {
    this.state.customer_id = event_id;
    this.selectize_instance.selectize.setValue(event_id, silent);
  },

  event_selected(val) {
    console.log(val);
    this.state.callback && this.state.callback(val);
  }

}
  
Object.assign( EventSelector.prototype, element);
Object.assign( EventSelector.prototype, ev_channel); 
  
EventSelector.prototype.HTML = ES5Template(function(){/**
  <div class='EventSelector form'>
    <select class='events' rv-on-change='this.event_selected' >
      <option rv-each-event='state.events' rv-value='event.id'>
        { event.starttime | dateformat 'ddd MMM Do YYYY' } [{event.id}] { event.name }
      </option>
    </select>
  </div>
**/}).untab(2);
  
EventSelector.prototype.CSS = ES5Template(function(){/**
  .EventSelector .selectize-input { width: 40em; }
**/}).untab(2);
  
rivets.components['event-selector'] = { 
  template:   function()        { return EventSelector.prototype.HTML; },
  initialize: function(el,attr) { return new EventSelector(el, attr);  }
}