
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

window.addEventListener('pageshow', fetch_data);
window.addEventListener('popstate', fetch_data2);

$(window).bind("unload", function() {});

function fetch_data() {
  loft_calendar && loft_calendar.refresh_data();
}

function fetch_data2() {
  loft_calendar && loft_calendar.refresh_data();
}