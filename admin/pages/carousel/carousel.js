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

  $widecroppie = $('#upload
    er .wide').croppie({
    viewport: { width: 480, height: 150 },
    boundary: { width: 530, height: 200 }
  });

  $tallcroppie = $('#uploader .tall').croppie({
    viewport: { width: 300, height: 300 },
    boundary: { width: 350, height: 350 }
  });

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  get_saved_slides();
  
});

function get_saved_slides() {
  $.get('/models/slides', function(slides) {
    data.slides = JSON.parse(slides);
  })
}