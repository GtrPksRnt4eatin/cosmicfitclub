data = {
  i: 0,
  images: [
    { "path": "/wide_freeclass_1920_tiny.png",  "msg": "Get Your First Class Free!" },
    { "path": "/wide_freeevents_1920_tiny.png", "msg": "Check Out Our Free Events!" },
    { "path": "/wide_membership_1920_tiny.png", "msg": "Join The Club! Become a Member Today!" },
    { "path": "/wide_handstand_1920_tiny.png",  "msg": "Learn How To Handstand!" }
  ],
  img_elements: [],
  msg_elements: []
}



$(document).ready(function() {

//    var imgfader = new ImgFader( 
//      id('imgfader_container'), 
//      [ "/wide_handstand.png",
//        "/wide_freeclass.png" 
//      ]
//    );

  data.img_elements.push( $(".frontpage img.img1") )
  data.img_elements.push( $(".frontpage img.img2") )
  data.msg_elements.push( $(".message_container .msg1")[0] )
  data.msg_elements.push( $(".message_container .msg2")[0] )

  setInterval( function() { transition_img(); }, 7000 );

  $('.img1, .img2').load(function(e){
    data.img_elements[0].addClass('transparent');
    data.img_elements[1].removeClass('transparent');
    data.msg_elements[0].addClass('transparent');
    data.msg_elements[1].removeClass('transparent');   
  });

});

function transition_img() {
  if(data.i>=data.images.length) { data.i = 0; }
  data.img_elements[1].attr('src', data.images[data.i]["path"] );
  data.msg_elements[1].textContent = data.images[data.i]["msg"];
  data.img_elements.push(data.img_elements.shift());
  data.msg_elements.push(data.msg_elements.shift());
  data.i = data.i + 1;
}