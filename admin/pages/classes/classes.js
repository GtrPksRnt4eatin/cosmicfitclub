var data = {
  classes: []
}

var ctrl = {
  del: function(e,m) {
    $.del(`/admin/classes/${m.slide.id}`, function() {
      data.classes.splice(data.slides.indexOf(m.slide),1);
    });
  }
}

$(document).ready(function() {

  $('#menu li').on('click', function(e) {
    window.location.href = e.target.getAttribute('href');
  });

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  get_saved_classes();

  id("newclasspic").onchange = function () {
    var reader = new FileReader();
    reader.onload = function (e) { id("newclasspreview").src = e.target.result; };
    reader.readAsDataURL(this.files[0]);
  };
  
});

function get_saved_classes() {
  $.get('/admin/classdefs', function(classes) {
    data.classes = JSON.parse(classes);
  })
} 