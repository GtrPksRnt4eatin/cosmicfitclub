function AspectImageChooser(parent) {
  
  this.state = {
    'croppie' : {},
    'width'   : 300,
    'height'  : 300 
  }

  this.bind_handlers(['build_croppie']);
  this.build_dom();
  this.mount(parent);
  this.load_styles();
  this.bind_dom();

}

AspectImageChooser.prototype = {
  constructor: AspectImageChooser,

  build_croppie: function(width,height) {
  	this.state.width  = width  | this.state.width;
  	this.state.height = height | this.state.height;
  	this.state.croppie = $(this.dom).find('.AspectImageChooser .croppie').croppie({
      viewport: { width: this.state.width, height: this.state.height },
      boundary: { width: this.state.width + 50, height: this.state.height + 50 },
      showZoomer: false
    });

    $(this.dom).find('.AspectImageChooser .cr-viewport::before').on('click', function() {
      $(this.dom).find('.AspectImageChooser input').trigger("click");
    }.bind(this));

    $('.AspectImageChooser .upload').on('change', function(el) {
      if (this.files && this.files[0]) {
        var reader = new FileReader();
        reader.onload = function (e) {
          $('.AspectImageChooser .upload').addClass('ready');
          this.state.croppie.croppie('bind', { url: e.target.result }).then(function(){ console.log('jQuery bind complete'); });   
        }
        reader.readAsDataURL(this.files[0]);
      }
      else { swal("Sorry - you're browser doesn't support the FileReader API"); }
    });
  },

  input_change: function(e,m) {
  	var x = 5;
  },

  show_modal: function(title, value, callback) {
    this.state.title = title;
    this.state.value = value;
    this.state.callback = callback;
    this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} );
  },

}

Object.assign( AspectImageChooser.prototype, element);
Object.assign( AspectImageChooser.prototype, ev_channel); 

AspectImageChooser.prototype.HTML =  ES5Template(function(){/**

  <div class="AspectImageChooser">
    <div class="croppie">
      <input class="upload" rv-on-change="this.input_change" type="file" accept="image/*"></input>
    </div>
  </div>
  
**/}).untab(2);

AspectImageChooser.prototype.CSS =  ES5Template(function(){/**
  
  .AspectImageChooser .upload.ready .cr-viewport::before {
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

**/}).untab(2);