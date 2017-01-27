$(document).ready( function() {

	$('#myform').submit(function(e){
      e.preventDefault();
      $.ajax({
        url:'/auth/password',
        type:'post',
        data:$('#myform').serialize(),
        success:function() { window.location.href = '/user';  },
        fail: function()   { $('#myform').shake(); }
    });

});