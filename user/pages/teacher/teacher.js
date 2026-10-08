// Bind preloaded `data` to the page using Rivets
include_rivets_dates();
$(function(){
  rivets.bind(document.body, { data: data });
});

// delegated checkin handler
$(document).on('click', '.tile.tile_ib.upcoming .checkin-btn', function(e){
	e.preventDefault();
	var $btn = $(this);
	var res_id = $btn.attr('data-reservation');
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

// no-op: data is preloaded and bound via Rivets
