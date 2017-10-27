$(document).ready(function() {

  $.get('/models/slides/kids', function(slides) {
    slides = JSON.parse(slides);
    slides.forEach( function(slide) {
      $('#imgscroller').slick('slickAdd',`<div><img alt='' class='sliderimg' src='${ slide.url }' /></div>`);
    }); 
  });

  $('#imgscroller').slick({
    dots: true,
    infinite: true,
    cssEase: 'linear',
    slidesToShow: 3,
    autoplay: true,
    autoplaySpeed: 1000,
    centerMode: true,
    fade: true
  });

  //images.forEach( function(path) { var elem =  $('#imgscroller').slick('slickAdd',`<div><img class='sliderimg' src='${ path }' /></div>`); });

});