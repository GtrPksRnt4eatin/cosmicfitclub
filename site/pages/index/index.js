data = {
  i: 0,
  images: [
    { "path": "/wide_freeclass_1920_tiny.png",  "msg": "Get Your First Class Free!" },
    { "path": "/wide_freeevents_1920_tiny.png", "msg": "Check Out Our Free Events!" },
    { "path": "/wide_membership_1920_tiny.png", "msg": "Join The Club! Become a Member Today!" },
    { "path": "/wide_handstand_1920_tiny.png",  "msg": "Learn How To Handstand!" }
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
  	transition_img(data.images[data.i]["path"]);
  }, 7000 );

  $('.img1, .img2').load(function(e){
    data.elements[0].addClass('transparent');
    data.elements[1].removeClass('transparent');
    data.elements.push(data.elements.shift());
    set_msg(data.images[data.i]["msg"]);
    data.i = data.i + 1;
  });

});

function transition_img(path) {
  data.elements[1].attr('src', path);
  //data.elements[0].addClass('transparent');
  //data.elements[1].removeClass('transparent');
  //data.elements.push(data.elements.shift());
}

function set_msg(msg) {
  var elem = $('.message');
  elem.removeClass('animate');
  elem[0].textContent = msg;
  void elem[0].offsetWidth;
  elem.addClass('animate');
}

//img.addEventListener('load', function() {
  // execute drawImage statements here
//}, false);