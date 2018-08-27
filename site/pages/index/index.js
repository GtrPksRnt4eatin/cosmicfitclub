data = {
  i = 0;
  images = [
    "/wide_handstand.png",
    "/wide_freeclass.png" 
  ],
  elements = []
}



$(document).ready(function() {
  var $frontpage = $("#headerimg")

  elements.push( $(".frontpage.img1") )
  elements.push( $(".frontpage.img2") )

  setInterval( function() {
  	if(i==images.count) { i = 0; }
  	transition_img(images[i])
  	i = i + 1;
  }, 1000 );  
  
});

function transition_img(path) {
  elements[1].attr('src')
  elements[0].addClass('transparent')
  elements[1].removeClass('transparent')
  elements.push(elements.shift());
}