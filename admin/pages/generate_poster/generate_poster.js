
$(document).ready(function() {

    popupmenu   = new PopupMenu( id('popupmenu_container') );
	img_chooser = new AspectImageChooser();

	img_chooser.ev_sub('show', popupmenu.show );
    img_chooser.ev_sub('image_cropped', function(val) {
      popupmenu.hide();
    });
});