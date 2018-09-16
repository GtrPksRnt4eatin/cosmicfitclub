data = {}
ctrl = {
  submit: function(e,m) {
  	var cmd = $('#command').val()
  	$.post('/admin/console', cmd, ctrl.on_return);
  },

  on_return: function(data) {
  	$('#results').val(data);
  }
}

$(document).ready(function(){
  rivets.bind( document.body, { data: data, ctrl: ctrl } );
});