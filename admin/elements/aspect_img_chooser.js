function AspectImageChooser(parent) {
  
  this.state = {
    'croppie'  : {},
    'width'    : 500,
    'height'   : 500,
    'filename' : ""
  }

  this.bind_handlers(['build_croppie', 'input_change', 'on_reader_load', 'load_url']);
  this.build_dom();
  this.mount(parent);
  this.load_styles();
  this.bind_dom();

  this.reader        = new FileReader();
  this.reader.onload = this.on_reader_load;
  this.croppie       = this.build_croppie();
  this.input         = $(this.dom).find('.upload')[0];

}

AspectImageChooser.prototype = {
  constructor: AspectImageChooser,

  build_croppie: function(width,height) {
  	this.state.width  = width  | this.state.width;
  	this.state.height = height | this.state.height;
  	this.croppie = $(this.dom).find('.croppie').croppie({
      viewport: { width: this.state.width, height: this.state.height },
      boundary: { width: this.state.width + 50, height: this.state.height + 50 },
      showZoomer: false
    })[0];

    $(this.dom).find('.cr-viewport').on('click', function() {
      $(this.input).trigger("click");
    }.bind(this));

    return this.croppie;
  },

  input_change: function(e,m) {
    if( !this.input.files    ) { console.log("Browser doesn't support FileReader API!"); return; }
    if( !this.input.files[0] ) { console.log("Browser doesn't support FileReader API!"); return; }
    this.state.filename = this.input.files[0].name;
    this.reader.readAsDataURL(this.input.files[0]);
  },

  on_reader_load: function(e) {
    this.load_url(e.target.result);
  },

  show_modal: function(title, value, callback) {
    this.state.title = title;
    this.state.value = value;
    this.state.callback = callback;
    this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} );
  },

  load_url: function(url) {
    $(this.dom).addClass('ready');
    this.croppie.croppie('bind', { url: url });
  },

  crop_image: function(filename,url,width,height) {
  }

}

Object.assign( AspectImageChooser.prototype, element);
Object.assign( AspectImageChooser.prototype, ev_channel); 

AspectImageChooser.prototype.HTML =  ES5Template(function(){/**

  <div class="AspectImageChooser">
    <div class="croppie">
      <input class="upload" rv-on-change="this.input_change" type="file" accept="image/*"></input>
    </div>
    <div class="toolbar">
      <span class='filename'>{ state.filename }</span>
      <button>Open</button>
      <button>Done</button>
      <button>Cancel</button>
    </div>
  </div>
  
**/}).untab(2);

AspectImageChooser.prototype.CSS =  ES5Template(function(){/**

  .AspectImageChooser {
    display: inline-block;
    vertical-align: middle;
  }
  
  .AspectImageChooser.ready .cr-viewport::before {
    content: none;
  }

  .AspectImageChooser .cr-viewport::before {
    content: 'Upload A File to Start Cropping';
    background: white;
    color: #AAA;
    width: 100%;
    height: 100%;
    font-size: 1.5em;
    box-sizing: border-box;
    padding: 2em;
    text-align: center;
    display: inline-block;
  }

  .AspectImageChooser .cr-image {
    display: none;
  }

  .AspectImageChooser.ready .cr-image {
    display: inline-block;
  }

**/}).untab(2);