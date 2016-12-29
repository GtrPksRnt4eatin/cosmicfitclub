var data = {
  events: [],
  newevent: {}
}

var ctrl = {

  get: function() {
    $.get('/models/events', function(events) {
      data.events = JSON.parse(events);
    });
  },
  
  add: function(e) {
    var data = new FormData( id('new') );
    var request = new XMLHttpRequest();
    request.open("POST", "/models/events");
    request.send(data);
    ctrl.get();
  },

  del: function(e,m) {
    $.del(`/models/events/${m.event.id}`, function() {
      data.events.splice( data.events.indexOf( m.event ), 1 );
    });
  }

}

$(document).ready(function() {

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  $('#menu li').on('click', function(e) { window.location.href = e.target.getAttribute('href'); });

  ctrl.get();

  id("newpic").onchange = function () {
    var reader = new FileReader();
    reader.onload = function (e) { id("newpreview").src = e.target.result; };
    reader.readAsDataURL(this.files[0]);
  };

  id('upload').onclick  = ctrl.add;
  
});


/*
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
*/