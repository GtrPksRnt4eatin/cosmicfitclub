function PromoSquare(el,attr) {
  this.dom = el;
  this.attr = attr;
  this.bind_handlers(['get_events', 'get_classes', 'next_promo']);

  this.state = {
    events: [],
    classes: [],
    current: null,
    index: 0,
    timer: setInterval(this.next_promo, 5000),
  }
  this.get_events();
  this.get_classes();
}

PromoSquare.prototype = {
  constructor: PromoSquare,

  get_events: function() {
    $.get("/models/events/future_all")
     .success( function(resp) { this.state['events'] = resp; }.bind(this) );
  },

  get_classes: function() {
    $.get("/models/classdefs/ranked_list")
     .success( function(resp) { this.state['classes'] = resp; }.bind(this) );
  },

  next_promo: function() {
    let isclass = this.state.index%2;
    let index = Math.floor(this.state.index/2);
    if(index > Math.max(this.state.classes.count, this.state.events.count)) {
      this.state.index = 0;
      this.next_promo();
      return;
    } 
    on_deck = isclass ? this.state.classes[index] : this.state.events[index];
    if(!on_deck) {
      this.state.index++;
      this.next_promo();
      return;
    } 
    this.state.current = on_deck;
  }
}

Object.assign( PromoSquare.prototype, element);

PromoSquare.prototype.HTML = `
  <img rv-src="this.state.current.image_url"/>
`.untab(2);

PromoSquare.prototype.CSS = `
`.untab(2);

rivets.components['promo-square'] = {
  template:   function()        { return PromoSquare.prototype.HTML },
  initialize: function(el,attr) { return new PromoSquare(el,attr);  }
}