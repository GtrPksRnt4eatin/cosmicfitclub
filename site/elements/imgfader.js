function ImgFader(parent, images) {

  this.state = {
  	i: 0,
    images: images,
    elements: []
  }

  this.build_dom(parent);
  this.load_styles();
  this.bind_handlers(['transition_to']);

}

ImgFader.prototype = {

  constructor: Schedule,

  transition_to: function(img_path) {
  	this.state.elements[1].attr( 'src', img_path );
    this.state.elements[0].addClass( 'transparent' );
    this.state.elements[1].removeClass( 'transparent' );
    this.state.elements.push( this.state.elements.shift() );
  }

}

Object.assign( ImgFader.prototype, element );
Object.assign( ImgFader.prototype, ev_channel );

ImgFader.prototype.HTML = ES5Template(function(){/**
  
  <div class='img_fader'>
    <div class='img_container'>
      <img class='img1'/>
      <img class='img2 transparent'/>
    </div>
  </div>

**/}).untab(2);

ImgFader.prototype.CSS = ES5Template(function(){/**

  .img_fader {
	overflow: hidden;
	display: flex;
	flex-direction: column;
	align-items: center;
	opacity: 0.9;
	height: 58vh;
  }

  .img_fader .img_container {
	display: inline;
    height: 100%;
  }

  .img_fader .img_container img {
	height: 100%;
	opacity: 1;
    -webkit-transition: opacity 2s linear;
    -moz-transition: opacity 2s linear;
    -o-transition: opacity 2s linear;
    transition: opacity 2s linear;
  }

  .img_fader .img_container img.img2 {
	margin-top: -58vh;
  }

  .img_fader .img_container img.transparent {
	opacity: 0;
  }

**/}).untab(2);