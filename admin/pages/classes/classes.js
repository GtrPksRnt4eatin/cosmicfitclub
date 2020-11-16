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

  edit: function(e,m) {
    location.href = `edit_class?id=${m.class.id}`;
  },

  moveup: function(e,m) {
    $.post(`/models/classdefs/${m.class.id}/moveup`, function() { get_saved_classes(); });
  },

  movedn: function(e,m) {
    $.post(`/models/classdefs/${m.class.id}/movedn`, function() { get_saved_classes(); });
  }

}

$(document).ready(function() {

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  get_saved_classes();

  id('new2').onclick = function(e) {
    $.post('/models/classdefs', JSON.stringify( { id: 0 } ) )
      .done( function(resp) { 
        window.location = `edit_class?id=${resp.id}` 
      }) 
  };
  
});

function get_saved_classes() {
  $.get('/models/classdefs', function(classes) {
    data.classes = classes;
  })
} 

function post_new_class(e){
  var data = new FormData( id('newclass') );
  var request = new XMLHttpRequest();
  request.open("POST", "/models/classdefs");
  request.send(data);
  get_saved_classes();
}