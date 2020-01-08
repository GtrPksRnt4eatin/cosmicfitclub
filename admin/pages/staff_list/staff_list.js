var path = "/models/staff"

data = {}

var ctrl = {

  del: function(e,m) {
    $.del(`${ path }/${ m.item.id }`, function() {
      data.items.splice(data.items.indexOf(m.item),1);
    });
  },

  moveup: function(e,m) {
    $.post(`${ path }/${ m.item.id }/moveup`, get_saved_items );
  },

  movedn: function(e,m) {
    $.post(`${ path }/${ m.item.id }/movedn`, get_saved_items );
  }

}

$(document).ready(function() {

  rivets.formatters.subscription_link = function(val) { return '/admin/subscription?id=' + val; }
  rivets.formatters.detail_link       = function(val) { return '/admin/staff_detail?id=' + val; }

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  get_saved_items();

  id("newpic").onchange = function () {
    var reader = new FileReader();
    reader.onload = function (e) { id("newpreview").src = e.target.result; };
    reader.readAsDataURL(this.files[0]);
  };

  id('new').onsubmit = function(e) { 
    cancelEvent(e); 
    return false; 
  };
  id('upload').onclick  = post_new_item;
  
});

function get_saved_items() {
  $.get( path + "/detail_list", function(items) { data.items = items; });
} 

function post_new_item(e){
  var data = new FormData( id('new') );
  var request = new XMLHttpRequest();
  request.open("POST", path );
  request.send(data);
  get_saved_items();
}
