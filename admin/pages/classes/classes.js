var data = {
  classes: [],
  newclass: {}
}

var ctrl = {

  del: function(e,m) {
    $.del(`/models/classdefs/${m.class.id}`, function() {
      data.classes.splice(data.classes.indexOf(m.class),1);
    });
  },

  moveup: function(e,m) {
    $.post(`/models/classdefs/${m.class.id}/moveup`, function() { get_saved_classes(); });
  },

  movedn: function(e,m) {
    $.post(`/models/classdefs/${m.class.id}/movedn`, function() { get_saved_classes(); });
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

  //id('upload').addEventListener( 'click', function() { id('newclass').submit(); });
  id('newclass').onsubmit = function(e) { 
    cancelEvent(e); 
    return false; 
  };
  id('upload').onclick  = post_new_class;
  
});

function get_saved_classes() {
  $.get('/models/classdefs', function(classes) {
    data.classes = JSON.parse(classes);
  })
} 

function post_new_class(e){
  var data = new FormData( id('newclass') );
  var request = new XMLHttpRequest();
  request.open("POST", "/models/classdefs");
  request.send(data);
  get_saved_classes();
}