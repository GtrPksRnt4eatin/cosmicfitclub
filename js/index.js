$(document).ready(function() {

  var images = [
    '/carousel/img01.jpg', 
    '/carousel/img02.jpg', 
    '/carousel/img03.jpg', 
    '/carousel/img04.jpg',
    '/carousel/img05.jpg',
    '/carousel/img06.jpg',
  ];

  $('#imgscroller').slick({
    variableHeight: true,
  	centerMode: true,
  	centerPadding: '60px',
  	variableWidth: true,
    slidesToShow: 3,
  	infinite: true,
  	autoplay: true,
    autoplaySpeed: 2000,
    slidesToShow: 1
  	
  });

  images.forEach( function(path) { var elem =  $('#imgscroller').slick('slickAdd',`<div><img class='sliderimg' src='${ path }' /></div>`); });

});