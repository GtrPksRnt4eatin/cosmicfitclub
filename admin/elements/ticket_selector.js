function TicketSelector(parent) {

  this.state = { 
    event_id: 0,
    event: null,
    event_sessions: [],
    event_tickets: []
  }

  this.bind_handlers([]);
  this.parent = parent;
  this.build_dom();
  this.mount(parent);
  this.bind_dom();
  this.load_styles();

}

TicketSelector.prototype = {

  constructor: TicketSelector,

  load_event: function(event_id) {
    $.get('/models/events/' + event_id)
     .done( function(evt) { this.state.event = evt; } )
     .fail( function()    { alert('failed to load event' + event_id); } )
  },

  load_event_data: function(event) {
  	this.state.event = event;
  },

  load_customer: function(customer_id) {

  },

  load_customer_data: function(customer) {
  	
  }

}

Object.assign( TicketSelector.prototype, element);
Object.assign( TicketSelector.prototype, ev_channel); 

TicketSelector.prototype.HTML =  ES5Template(function(){/**
  <div class='ticket_selector'>
    <div class='price' rv-each-price='state.event.prices'> 
      <span>{price.title}</span>
      <span>{price.member_price}</span>
      <span>{price.full_price}</span>
    </div>
  </div>
**/}).untab(2);

TicketSelector.prototype.CSS = ES5Template(function(){/**
  .ticket_selector {
	
  }
**/}).untab(2);
