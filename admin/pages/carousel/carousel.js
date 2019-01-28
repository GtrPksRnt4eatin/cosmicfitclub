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

  $widecroppie = $('#uploader .wide').croppie({
    viewport: { width: 480, height: 150 },
    boundary: { width: 530, height: 200 },
    showZoomer: false
  });

  $tallcroppie = $('#uploader .tall').croppie({
    viewport: { width: 300, height: 300 },
    boundary: { width: 350, height: 350 },
    showZoomer: false
  });

  $('#upload_wide').on('change', function() {
    if (this.files && this.files[0]) {
      var reader = new FileReader();
      reader.onload = function (e) {
        $('#uploader .wide').addClass('ready');
        $widecroppie.croppie('bind', { url: e.target.result }).then(function(){ console.log('jQuery bind complete'); });   
      }
      reader.readAsDataURL(this.files[0]);
    }
    else { swal("Sorry - you're browser doesn't support the FileReader API"); }
  });

  $('#upload_tall').on('change',function() {
    if (this.files && this.files[0]) {
      var reader = new FileReader();
      reader.onload = function (e) {
        $('#uploader .tall').addClass('ready');
        $tallcroppie.croppie('bind', { url: e.target.result }).then(function(){ console.log('jQuery bind complete'); });   
      }
      reader.readAsDataURL(this.files[0]);
    }
    else { swal("Sorry - you're browser doesn't support the FileReader API"); }
  });

  $('.wide_result').on('click', function (ev) {
    $widecroppie.croppie('result', {
      type: 'blob',
      size: { width: 1920, height: 600}
      }).then(function (resp) {
        $('#result').src = urlCreator.createObjectURL(resp);
      });
    });

    $('.tall_result').on('click', function (ev) {
    $tallcroppie.croppie('result', {
      type: 'blob',
      size: { width: 600, height: 600}
      }).then(function (resp) {
        $('#result').src = urlCreator.createObjectURL(resp);
      });
    });

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  get_saved_slides();
  
});

function get_saved_slides() {
  $.get('/models/slides', function(slides) {
    data.slides = JSON.parse(slides);
  })
}