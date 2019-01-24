data = {
  i: 0,
  first: true,
  images: [
    { "path": "/wide_freeclass_1920_tiny.png",  "msg": "Get Your First Class Free!",            "url": "/first_class_free" },
    { "path": "/class-core-wide01_tiny.png",    "msg": "Strengthen and Tone Your Core!",        "url": "/class/32" },
    { "path": "/wide_freeevents_1920_tiny.png", "msg": "Check Out Our Free Events!",            "url": "/free_events" },
    { "path": "/space-rental01_tiny.png",       "msg": "Planning Your Own Event?",              "url": "/"         },
    { "path": "/f2h_tiny.png",                  "msg": "Foot to Hand and Hand to Hand!",        "url": "/class/44" },
    { "path": "/wide_membership_1920_tiny.png", "msg": "Join The Club! Become a Member Today!", "url": "/become_a_member"  },
    { "path": "/wide_handstand_1920_tiny.png",  "msg": "Learn How To Handstand!",               "url": "/class/74" }
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
  data.msg_elements.push( $(".message_container .msg1") )
  data.msg_elements.push( $(".message_container .msg2") )

  setInterval( function() { transition_img(); }, 6000 );

  $('.img1, .img2').load(function(e){
    if(data.first) { data.first = false; return; }
    $('#pagebanner').attr('href', data.images[data.i]["url"]);
    data.img_elements[0].addClass('transparent');
    data.img_elements[1].removeClass('transparent');
    data.msg_elements[1].removeClass('transparent');
    data.msg_elements[0].addClass('transparent');
    data.img_elements.push(data.img_elements.shift());
    data.msg_elements.push(data.msg_elements.shift());
  });

});

function transition_img() {
  data.i = data.i + 1;
  if(data.i>=data.images.length) { data.i = 0; }
  data.img_elements[1].attr('src', data.images[data.i]["path"] );
  data.msg_elements[1][0].textContent = data.images[data.i]["msg"];
}