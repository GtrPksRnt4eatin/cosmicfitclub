data = {}
ctrl = {
  submit: function(e,m) {
  	var cmd = $('#command').value()
  	$.post('/admin/console', cmd, ctrl.on_return);
  },

  on_return: function(data) {
  	$('#results').value(data);
  }
}

$(document).ready(function(){
  rivets.bind( document.body, { data: data, ctrl: ctrl } );
});