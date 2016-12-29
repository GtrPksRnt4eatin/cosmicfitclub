var data = {
  slides: []
}

var ctrl = {
  del: function(e,m) {
    $.del(`/models/slides/${m.slide.id}`, function() {
      data.slides.splice(data.slides.indexOf(m.slide),1);
    });
  }
}

$(document).ready(function() {

  $('#menu li').on('click', function(e) {
    window.location.href = e.target.getAttribute('href');
  });

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  get_saved_slides();
  
});

function get_saved_slides() {
  $.get('/models/slides', function(slides) {
    data.slides = JSON.parse(slides);
  })
}