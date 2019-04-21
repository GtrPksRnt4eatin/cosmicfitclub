$(document).ready(function() {

  $.get('/models/slides', function(slides) {
    slides = JSON.parse(slides);
    slides.forEach( function(slide) {
      $('#imgscroller').slick('slickAdd',`<div><img alt='' class='sliderimg' src='${ slide.url }' /></div>`);
    }); 
  });

  $('#imgscroller').slick({
    variableHeight: true,
  	centerMode: true,
  	centerPadding: '60px',
  	variableWidth: true,
  	infinite: true,
  	autoplay: true,
    autoplaySpeed: 2000,
    slidesToShow: 1
  });

});