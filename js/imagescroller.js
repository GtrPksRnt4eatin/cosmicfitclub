function ImageScroller(parent) {
  this.state = {
  	images: []
  }
  this.build_dom(parent);
  this.bind_dom();
  this.load_styles();
}

ImageScroller.prototype = {
  constructor: ImageScroller,

  build_dom(parent) { this.dom = render(this.HTML);  if(!empty(parent)) parent.appendChild(this.dom); },
  bind_dom()        { rivets.bind(this.dom, { data: this.state, obj: this }); },
  load_styles()     { load_css('fretboard_styles', this.CSS); },

  load_images(images) {
    this.state.images = images;
  }
}

ImageScroller.prototype.HTML = `
  <div id='ImageScroller'>
    <div rv-each-img='data.images'>
      <img rv-src='img'>
    </div>
  </div>
`.untab(2);

ImageScroller.prototype.CSS = `
  #ImageScroller {
    white-space: nowrap;
  }
  
  #ImageScroller div {
  	display: inline-block;
  }

  #ImageScroller img { 
  	height: 100%;   
  }
`.untab(2);