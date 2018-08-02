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

TicketSelector.prototype.HTML = ES5Template(function(){/**
  <div class='ticket_selector'>
    <div class='price' rv-each-price='state.event.prices'> 
      <span>{price.title}</span>
      <span>Member Price: {price.member_price | money}</span>
      <span>Full Price: {price.full_price | money}</span>
    </div>
  </div>
**/}).untab(2);

TicketSelector.prototype.CSS = ES5Template(function(){/**
  .ticket_selector {
	  padding: 1em;
    box-shadow: 0 0 3px white;
  }

  .ticket_selector .price {
    
  }

  .ticket_selector .price span {
    display: inline-block;
    width: 10em;
  }
**/}).untab(2);
