// Simple teacher check-in handler for upcoming classes
$(document).on('click', '.tile.tile_ib.upcoming .checkin-btn', function(e){
	e.preventDefault();
	var $btn = $(this);
	var res_id = $btn.attr('data-reservation') || $btn.data('reservation');
	if(!res_id) return alert('Reservation id missing');
	$btn.prop('disabled', true).text('Checking in...');
	$.post('/models/classdefs/reservations/' + res_id + '/checkin')
		.done(function(resp){
			$btn.replaceWith('<span class="checkin">✓ Checked In</span>');
		})
		.fail(function(){
			alert('Checkin failed');
			$btn.prop('disabled', false).text('Check In');
		});
});
