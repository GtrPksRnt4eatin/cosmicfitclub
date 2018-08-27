data = {
  i: 0,
  images: [
    "/wide_handstand.png",
    "/wide_freeclass.png" 
  ],
  elements: []
}



$(document).ready(function() {

  data.elements.push( $(".frontpage.img1") )
  data.elements.push( $(".frontpage.img2") )

  setInterval( function() {
  	if(data.i>=data.images.length) { data.i = 0; }
  	transition_img(data.images[data.i])
  	data.i = data.i + 1;
  }, 1000 );  

});

function transition_img(path) {
  console.log("Loading: " + path)
  data.elements[1].attr('src')
  data.elements[0].addClass('transparent')
  data.elements[1].removeClass('transparent')
  data.elements.push(data.elements.shift());
}