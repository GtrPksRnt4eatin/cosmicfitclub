var data = {
  classes: [],
  newclass: {}
}

var ctrl = {
  del: function(e,m) {
    $.del(`/admin/classdefs/${m.class.id}`, function() {
      data.classes.splice(data.classes.indexOf(m.class),1);
    });
  }
}

$(document).ready(function() {

  $('#menu li').on('click', function(e) {
    window.location.href = e.target.getAttribute('href');
  });

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  get_saved_classes();

  id("newpic").onchange = function () {
    var reader = new FileReader();
    reader.onload = function (e) { id("newpreview").src = e.target.result; };
    reader.readAsDataURL(this.files[0]);
  };


  
});

function get_saved_classes() {
  $.get('/admin/classdefs', function(classes) {
    data.classes = JSON.parse(classes);
  })
} 

function post_new_class(){
  $.post('/admin/classes', $('#newclass').serialize(), function() {
    
  });
}