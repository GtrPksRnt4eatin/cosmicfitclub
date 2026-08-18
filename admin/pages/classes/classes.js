var data = {
  active: [],
  inactive: [],
  cancelled: []
}

var ctrl = {

  del: function(e,m) {
    if (!confirm(`Deactivate "${m.class.name}"?`)) return;
    $.del(`/models/classdefs/${m.class.id}`, function() {
      get_saved_classes();
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
  },

  force_del: function(e,m) {
    if (!confirm(`Permanently delete "${m.class.name}"? This cannot be undone.`)) return;
    $.del(`/models/classdefs/${m.class.id}/force`, function() {
      get_saved_classes();
    });
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
  $.get('/models/classdefs/admin_grouped', function(resp) {
    data.active   = resp.active;
    data.inactive = resp.inactive;
    data.cancelled = resp.cancelled;
  });
} 

function post_new_class(e){
  var data = new FormData( id('newclass') );
  var request = new XMLHttpRequest();
  request.open("POST", "/models/classdefs");
  request.send(data);
  get_saved_classes();
}