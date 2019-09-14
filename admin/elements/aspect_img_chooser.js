function AspectImageChooser(parent) {
  
  this.state = {
    'width'    : 500,
    'height'   : 500,
    'filename' : '',
    'url'      : null
  }

  this.bind_handlers(['build_croppie', 'input_change', 'on_reader_load', 'load_url', 'open_file', 'edit_image', 'resize', 'rebuild_croppie', 'save_crop']);
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
      boundary: { width: this.state.width + 100, height: this.state.height + 100 },
      showZoomer: false
    });

    $(this.dom).find('.cr-viewport').on('click', this.open_file);

    if(this.state.url) { this.load_url(this.state.url); }

    return this.croppie;
  },

  open_file: function(e,m) {
    $(this.input).trigger("click");
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
    this.state.url = url
    $(this.dom).addClass('ready');
    this.croppie.croppie('bind', { url: url });
  },

  edit_image: function(filename,url) {
    this.state.filename = filename;
    this.load_url(url);
  },

  save_crop: function() {
    this.ev_fire('image_cropped', { 'filename': this.state.filename, 'blob': this.croppie.croppie.result('blob') } )
  },

  resize: function(width,height) {
    this.state.width = width;
    this.state.height = height;
    this.rebuild_croppie();
  },

  rebuild_croppie: function() {
    this.croppie.croppie('destroy');
    this.build_croppie();
  }

}

Object.assign( AspectImageChooser.prototype, element);
Object.assign( AspectImageChooser.prototype, ev_channel); 

AspectImageChooser.prototype.HTML =  ES5Template(function(){/**

  <div class="AspectImageChooser">
    <div class="toolbar">
      <input rv-value='state.width'></input> x <input rv-value='state.height'></input>
      <button rv-on-click='this.rebuild_croppie'>Resize</button>
    </div>
    <div class="croppie">
      <input class="upload" rv-on-change="this.input_change" type="file" accept="image/*"></input>
    </div>
    <div class="toolbar">
      <span class='filename'>
        <span>{ state.filename }</span>
      </span>
      <button rv-on-click='this.open_file'>Upload</button>
      <button>Save Crop</button>
    </div>
  </div>
  
**/}).untab(2);

AspectImageChooser.prototype.CSS =  ES5Template(function(){/**

  .AspectImageChooser {
    display: inline-block;
    vertical-align: middle;
    padding: 150px;
    background: rgb(20,20,20);
    border-radius: 50px;
    box-shadow: 0 0 10px black; 
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

  .AspectImageChooser .upload {
    opacity: 0;
    width: 0;
    height: 0;
  }

  .AspectImageChooser .cr-image {
    display: none;
  }

  .AspectImageChooser.ready .cr-image {
    display: inline-block;
  }

  .AspectImageChooser .toolbar {
    background: rgba(50,50,50,1);
    font-size: 1em;
    display: flex
  }

  .AspectImageChooser .toolbar .filename {
    flex: 1;
  }

  .AspectImageChooser .toolbar .filename span {
    max-width: 25em;
    text-overflow: ellipsis;
    overflow: hidden;
    display: inline-block;
  }

  .AspectImageChooser .toolbar button {
    font-size: 1em;
    background: rgb(100,100,100);
    color: white;
    padding: 0.25em 1em;
    border: 0;
    cursor: pointer;
    flex: 0 0 8em;
    margin-left: 0.5em;
  }

**/}).untab(2);