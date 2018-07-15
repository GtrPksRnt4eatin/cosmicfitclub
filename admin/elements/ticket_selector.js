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

}

Object.assign( TicketSelector.prototype, element);
Object.assign( TicketSelector.prototype, ev_channel); 

TicketSelector.prototype.HTML =  ES5Template(function(){/**
  <div class='ticket_selector'>
    
  </div>
**/}).untab(2);

TicketSelector.prototype.CSS = ES5Template(function(){/**
  .ticket_selector {
	
  }
**/}).untab(2);
