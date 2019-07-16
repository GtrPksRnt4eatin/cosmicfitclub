data = {
  staff: {}
}

var ctrl = {
  edit_headshot: function(e,m) {},
  edit_name:     function(e,m) { edit_text.show("Edit Staff Name",  data.staff.name,   function(val) { data.staff.name = val;  post_staff_details({ name:  val }); } ) },
  edit_title:    function(e,m) { edit_text.show("Edit Staff Title", data.staff.title,  function(val) { data.staff.title = val; post_staff_details({ title: val }); } ) },
  edit_bio:      function(e,m) { edit_text.show_long("Edit Staff Bio", data.staff.bio, function(val) { data.staff.bio   = val; post_staff_details({ bio: val   }); } ) }
}

$(document).ready(function() {

  popupmenu = new PopupMenu( id('popupmenu_container') );
  edit_text = new EditText();

  edit_text.ev_sub('show', popupmenu.show );
  edit_text.ev_sub('done', popupmenu.hide );
  popupmenu.ev_sub('close', edit_short_text.cancel);

  rivets.formatters.subscription_link = function(val) { return '/admin/subscription?id=' + val; }
  
  include_rivets_dates();

  rivets.formatters.count = function(val) { return ( val ? val.length : 0 ); }

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  get_staff_details();
  
});

function get_staff_details() {
  $.get( "/models/staff/" +  getUrlParameter('id') + "/details", function(resp) { data.staff = resp; });
}

function post_staff_details(values) {
  $.post( "/models/staff/" + data.staff.id, { values: values } )
   .success( get_staff_details )
   .fail( alert("Failed To Save Updated Value") )
}