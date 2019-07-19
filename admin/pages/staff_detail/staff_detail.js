data = {
  staff: {}
}

var ctrl = {
  edit_headshot: function(e,m) {},
  edit_name:     function(e,m) { edit_text.show("Edit Staff Name",  data.staff.name,   function(val) { data.staff.name = val;  post_staff_details({ name:  val }); } ) },
  edit_title:    function(e,m) { edit_text.show("Edit Staff Title", data.staff.title,  function(val) { data.staff.title = val; post_staff_details({ title: val }); } ) },
  edit_bio:      function(e,m) { edit_text.show_long("Edit Staff Bio", data.staff.bio, function(val) { data.staff.bio   = val; post_staff_details({ bio: val   }); } ) },
  create_sub:    function(e,m) { $.post("/models/staff/" + data.staff.id + "/create_sub", function() { get_staff_details(); } ); }
}

$(document).ready(function() {

  popupmenu = new PopupMenu( id('popupmenu_container') );
  edit_text = new EditText();

  edit_text.ev_sub('show', popupmenu.show );
  edit_text.ev_sub('done', popupmenu.hide );
  popupmenu.ev_sub('close', edit_text.cancel);

  init_rivets();
  get_staff_details();
  
});

function init_rivets() {
  include_rivets_dates();
  rivets.formatters.subscription_link = function(val) { return '/admin/subscription?id=' + val; }
  rivets.formatters.count             = function(val) { return ( val ? val.length : 0 ); }
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
}

function get_staff_details() {
  $.get( "/models/staff/" +  getUrlParameter('id') + "/details", function(resp) { data.staff = resp; });
}

function post_staff_details(values) {
  $.post( "/models/staff/" + data.staff.id, { values: values } )
   .success( get_staff_details )
   .fail( alert("Failed To Save Updated Value") )
}