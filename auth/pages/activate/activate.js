$(document).ready( function() {

	$('#myform').submit(function(e){
      e.preventDefault();
      $.ajax({
        url:'/auth/password',
        type:'post',
        data:$('#myform').serialize(),
        success:function() { window.location.href = '/user';  },
        error: function(resp)  { $('.tile').shake(); $('.errors').innerText=resp.responseText; }
      });
    });

});