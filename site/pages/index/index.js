data = {
  i: 0,
  images: [
    { "path": "/wide_handstand.png", "msg": "Learn How To Handstand!" },
    { "path": "/wide_freeclass.png", "msg": "Get Your First Class Free!" }
  ],
  elements: []
}



$(document).ready(function() {

//    var imgfader = new ImgFader( 
//      id('imgfader_container'), 
//      [ "/wide_handstand.png",
//        "/wide_freeclass.png" 
//      ]
//    );

  data.elements.push( $(".frontpage img.img1") )
  data.elements.push( $(".frontpage img.img2") )

  setInterval( function() {
  	if(data.i>=data.images.length) { data.i = 0; }
  	transition_img(data.images[data.i]["path"])
  	data.i = data.i + 1;
  }, 5000 );



});

function transition_img(path) {
  data.elements[1].attr('src', path);
  data.elements[0].addClass('transparent');
  data.elements[1].removeClass('transparent');
  data.elements.push(data.elements.shift());
}

//img.addEventListener('load', function() {
  // execute drawImage statements here
//}, false);