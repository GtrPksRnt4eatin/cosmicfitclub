function EventSelector(el,view, attr) {
  this.dom = el;

  this.state = {
    events: attr['events'] || [],
    event_id: null
  }

  this.bind_handlers(['fetch_events']);
  this.load_styles();
  setTimeout(function() {
    attr['events'] || this.fetch_events();
  }.bind(this),100);
}
  
EventSelector.prototype = {
  constructor: EventSelector,

  fetch_events() {
    $.get('/models/events/list', function(val) { 
      this.state.events = val; 
      $('select', this.dom)[0].selectize.refreshItems();
    }.bind(this) );
  }
}
  
Object.assign( EventSelector.prototype, element);
Object.assign( EventSelector.prototype, ev_channel); 
  
EventSelector.prototype.HTML = ES5Template(function(){/**
  <div class='EventSelector form'>
    <select>
      <option value='0'>None</option>
      <option rv-each-event='state.events' rv-value='event.id'>
        { event.name }
      </option>
  </div>
**/}).untab(2);
  
EventSelector.prototype.CSS = ES5Template(function(){/**
  .EventSelector { }
**/}).untab(2);
  
rivets.components['event-selector'] = { 
  template:   function()        { return EventSelector.prototype.HTML; },
  initialize: function(el,attr) { 
    return new EventSelector(el, this.view, attr);   
  }
}