function AspectImageChooser(parent) {
  this.state = {

  }

  this.bind_handlers([]);
  this.build_dom();
  this.mount(parent);
  this.load_styles();
  this.bind_dom();

}

AspectImageChooser.prototype = {
  constructor: AspectImageChooser,

}

Object.assign( AspectImageChooser.prototype, element);
Object.assign( AspectImageChooser.prototype, ev_channel); 

AspectImageChooser.prototype.HTML =  ES5Template(function(){/**

**/}).untab(2);

AspectImageChooser.prototype.CSS =  ES5Template(function(){/**

**/}).untab(2);