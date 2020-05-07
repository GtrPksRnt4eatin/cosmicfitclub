data = {
  sched: {}
}

ctrl = {

}

$(document).ready(function() {

  popupmenu      = new PopupMenu( id('popupmenu_container') );
  edit_text      = new EditText();
  img_chooser    = new AspectImageChooser();

  img_chooser.ev_sub('show', popupmenu.show );
  img_chooser.ev_sub('image_cropped', function(val) {
    popupmenu.hide();
    fd = new FormData(); 
    fd.append('image', val['blob'], val['filename'] ); 
    request = new XMLHttpRequest();
    request.open( "POST", "/models/classdefs/schedules" + data.schedule.id + "/image", true );
    request.onload  = function(e) { get_sched_details(); }
    request.onerror = function(e) { alert("Failed to Upload Image"); }
    request.send(fd);
  });

  edit_text.ev_sub('show', popupmenu.show );
  edit_text.ev_sub('done', popupmenu.hide );

  popupmenu.ev_sub('close', edit_text.cancel);

  init_rivets();
  get_sched_details();

});

function init_rivets() {
  include_rivets_dates();
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
}

function get_sched_details() {
  $.get( "/models/classdefs/schedules/" +  getUrlParameter('id'), function(resp) { data.sched = resp; });
}