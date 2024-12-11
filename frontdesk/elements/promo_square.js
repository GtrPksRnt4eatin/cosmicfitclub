function PromoSquare(el,attr) {
  this.dom = el;
  this.attr = attr;
  this.bind_handlers(['get_events', 'get_classes', 'next_promo']);

  this.state = {
    events: [],
    classes: [],
    current: null,
    index: 0,
    timer: setInterval(this.next_promo, 10000),
  }

  this.load_styles();
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
    if(index > Math.max(this.state.classes.length, this.state.events.length)) {
      this.state.index = 0;
      this.next_promo();
      return;
    } 
    on_deck = isclass ? this.state.classes[index] : this.state.events[index];
    this.state.index++;
    if(on_deck) { this.state.current = on_deck; } 
    else        { this.next_promo(); } 
  }
}

Object.assign( PromoSquare.prototype, element);

PromoSquare.prototype.HTML = `
  <img rv-src="state.current.image_url"/>
  <div class='poster_lines'>
    <div rv-each-line="state.current.poster_lines">{line}</div>
  </div>
  `.untab(2);

PromoSquare.prototype.CSS = `
  promo-square {
    position: relative;
    box-sizing: border-box;
  }

  promo-square img { 
    border-radius: 2em;
    box-shadow: 0 0 8px white;
    background: rgba(0,0,0,0.2);
    width:100%;
    height: 100%;
  }

  promo-square .poster_lines {
    position: absolute;
    background: rgba(0,0,0,0.7);
    border-radius: 0 0 2em 2em;
    bottom: 0;
    left: 0; right: 0;
  }
`.untab(2);

rivets.components['promo-square'] = {
  template:   function()        { return PromoSquare.prototype.HTML },
  initialize: function(el,attr) { return new PromoSquare(el,attr);  }
}