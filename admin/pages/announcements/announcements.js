ctrl = {

  active: function(e,m) {
  	var val = $(e.target).is(':checked');
  	if (val) { $('#banner').show(); }
  	else     { $('#banner').hide(); }
  	$.post('/models/settings/announcement_active', JSON.stringify(val), 'json' );
  },
  	
  background: function(e,m) {
  	var val = $(e.target).val();
  	$('#banner').css('backgroundColor',val);
  	$.post('/models/settings/announcement_background', JSON.stringify(val), 'json' );
  },
  	
  message: function(e,m) {
  	var val = $(e.target).val();
    $('#banner').text(val);
    $.post('/models/settings/announcement_message', JSON.stringify(val), 'json' );
  },

  href: function(e,m) {
    var val = $(e.target).val();
    $('#banner').attr("href", val);
    $.post('/models/settings/announcement_href', JSON.stringify(val), 'json' );
  }
  	
}
  
  
$(document).ready(function() {
  	
  include_rivets_color();
  rivets.bind( $('body'), { data: data, ctrl: ctrl } );  
 	
});