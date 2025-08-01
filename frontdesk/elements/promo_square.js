function PromoSquare(el,attr) {
  this.dom = el;
  this.attr = attr;
  this.bind_handlers(['get_events', 'get_classes', 'next_promo']);

  this.state = {
    events: [],
    classes: [],
    current: { poster_lines: ["Loading Promos...", "Please Wait"]},
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
     .success( function(resp) { 
       this.state['events'] = resp;
       this.state['events'].forEach(function(event) {
         fetch(event.image_url)
          .then(function(resp) { return resp.blob(); })
          .then(function(blob) { event.image_url = URL.createObjectURL(blob); })
       });
     }.bind(this));
  },

  get_classes: function() {
    $.get("/models/classdefs/ranked_list")
     .success( function(resp) { 
       this.state['classes'] = resp; 
       this.state['classes'].forEach(function(cls) {
        fetch(cls.image_url)
         .then(function(resp) { return resp.blob(); })
         .then(function(blob) { cls.image_url = URL.createObjectURL(blob); });
        if(cls.video_urls.length) {
          fetch(cls.video_urls[0])
           .then(function(resp) { return resp.blob(); })
           .then(function(blob) { cls.video_url = URL.createObjectURL(blob); });
        }
      });
     }.bind(this) );
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
    if(!on_deck) { this,next_promo(); }
    else { 
      this.state.current = on_deck; 
      if(this.state.current.video_url) { document.getElementById('promo_vid').play(); }
    }
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
    text-align: center;
  }

  promo-square img, promo-square video { 
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
    padding: 0.3em 0;
  }
`.untab(2);

rivets.components['promo-square'] = {
  template:   function()        { return PromoSquare.prototype.HTML },
  initialize: function(el,attr) { return new PromoSquare(el,attr);  }
}