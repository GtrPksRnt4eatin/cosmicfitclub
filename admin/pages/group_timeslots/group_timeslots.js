
var loft_calendar;

$(document).ready( function() {
  popupmenu      = new PopupMenu( id('popupmenu_container') );
  custy_selector = new CustySelector();

  custy_selector.ev_sub('show'       , popupmenu.show );
  custy_selector.ev_sub('close_modal', popupmenu.hide );
  custy_selector.show_add_form();
  
  var view = rivets.bind($('body'), { data : {} } );
  loft_calendar = get_element(view,'loft-calendar');
});

// disable bfcache
$(window).bind("unload", function() {});

window.addEventListener('pageshow', function() {
  loft_calendar && loft_calendar.refresh_data();
});