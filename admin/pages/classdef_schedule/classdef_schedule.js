data = {
  sched: {}
}

ctrl = {

  edit_image: function(e,m) {
    img_chooser.resize(500,500); 
    if(data.sched.image_data) {
      img_chooser.load_image(data.sched.image_data.original.metadata.filename, data.sched.image_url);
    }
    img_chooser.show_modal(null,null,function(val) {
      popupmenu.hide();
      post_image('/models/classdefs/schedules' + data.sched.id + '/image', val['filename'], val['blob']);
    }); 
  },

  upload_video: function(e,m) {
    if (e.target.files && e.target.files[0]) {
      var fd = new FormData();
      fd.append('video', e.target.files[0], e.target.files[0].name);
      var request = new XMLHttpRequest();
      request.open("POST", "/models/classdefs/schedules/" + data.sched.id + "/video", true);
      request.onload = function(e) { get_sched_details(); }
      request.onerror = function(e) { alert("Failed to Upload Video"); }
      request.send(fd);
    }
  }

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
    request.open( "POST", "/models/classdefs/schedules/" + data.sched.id + "/image", true );
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
  rivets.formatters.teachernames = function(val) { return val ? val.map(function(x) { return x.name }).join(', ') : ''; }
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
}

function get_sched_details() {
  $.get( "/models/classdefs/schedules/" +  getUrlParameter('id'), function(resp) { data.sched = resp; });
}