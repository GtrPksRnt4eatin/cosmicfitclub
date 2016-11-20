function ImageScroller(parent) {
  this.build_dom(parent);
  this.load_styles();
}

ImageScroller.prototype = {
  constructor: ImageScroller,
  build_dom:     function(parent) { this.dom = render(this.HTML);  if(!empty(parent)) parent.appendChild(this.dom); },
  load_styles:   function()       { load_css('fretboard_styles', this.CSS); },
}

ImageScroller.prototype.HTML = `
  <div id='ImageScroller'>

  </div>
`.untab(2);

ImageScroller.prototype.CSS = `
  #ImageScroller {

  }


`.untab(2);