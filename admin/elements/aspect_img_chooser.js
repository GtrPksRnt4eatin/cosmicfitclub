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
    el = $(this.dom).find('.croppie')[0];
    width = window.innerWidth * 0.6
    height = width * this.state.height / this.state.width
  	this.croppie = new Croppie( el, {
      viewport: { width: width, height: height },
      boundary: { width: width * 1.1, height: height * 1.1 },
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
    if(!this.state.url) { this.open_file(); }
  },

  load_url: function(url) {
    this.state.url = url
    $(this.dom).addClass('ready');
    this.croppie.bind({ url: url });
  },

  edit_image: function(filename,url) {
    this.state.filename = filename;
    this.load_url(url);
  },

  save_crop: function() {
    this.croppie.result({
      type: 'blob', 
      size: { width: this.state.width, height: this.state.height }
    }).then( function(val) {
      filename = this.state.filename.replace(/\..*/, '.png')
      this.ev_fire('image_cropped', { 'filename': filename, 'blob': val } )
      if(this.state.callback) { this.state.callback.call(null,{ 'filename': filename, 'blob': val }); }
      this.state.callback = null;
    }.bind(this))
  },

  resize: function(width,height) {
    this.state.width = width;
    this.state.height = height;
    this.rebuild_croppie();
  },

  rebuild_croppie: function() {
    this.croppie.destroy();
    this.build_croppie();
  }

}

Object.assign( AspectImageChooser.prototype, element);
Object.assign( AspectImageChooser.prototype, ev_channel); 

AspectImageChooser.prototype.HTML =  ES5Template(function(){/**

  <div class="AspectImageChooser">
    <div class="toolbar">
      <input rv-value='state.width'></input>
      <span class='filler'>x</span>
      <input rv-value='state.height'></input>
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
      <button rv-on-click='this.save_crop'>Save Crop</button>
    </div>
  </div>
  
**/}).untab(2);

AspectImageChooser.prototype.CSS =  ES5Template(function(){/**

  .AspectImageChooser {
    display: inline-block;
    vertical-align: middle;
    padding: 5vw;
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
    display: none;
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

  .AspectImageChooser .toolbar input {
    width: 3em;
    background: rgba(255,255,255,0.2);
    color: white;
    border: 0;
    padding: 0 1em;
  }

  .AspectImageChooser .toolbar .filler {
    padding: 0 0.25em;
  }

  img.blank {
    background-image: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=);
    width: 15em;
    height: 15em;
  }

**/}).untab(2);