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

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  get_saved_slides();
  
});

function get_saved_slides() {
  $.get('/models/slides', function(slides) {
    data.slides = slides;
  })
}