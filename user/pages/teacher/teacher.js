// Bind preloaded `data` to the page using Rivets
include_rivets_dates();
$(function(){
  rivets.bind(document.body, { data: data });
});

// delegated checkin handler (works anywhere a .checkin-btn appears)
$(document).on('click', '.checkin-btn', function(e){
	e.preventDefault();
	var $btn = $(this);
	var res_id = $btn.attr('data-reservation');
	if(!res_id) return alert('Reservation id missing');
	$btn.prop('disabled', true).text('Checking in...');
	$.post('/models/classdefs/reservations/' + res_id + '/checkin')
		.done(function(resp){
			var updated = false;
			try{
				if(window.data && data.upcoming){
					data.upcoming.forEach(function(occ){
						if(occ.reservations){
							occ.reservations.forEach(function(r){
								if(String(r.id) == String(res_id)){
									r.checked_in = !r.checked_in;
									updated = true;
								}
							});
						}
					});
				}
			}catch(err){ updated = false }
			// update DOM immediately for snappy feedback
			if(updated){
				$btn.replaceWith('<span class="checkin" data-reservation="'+res_id+'">✓ Checked In</span>');
			} else {
				$btn.replaceWith('<span class="checkin" data-reservation="'+res_id+'">✓ Checked In</span>');
			}
		})
		.fail(function(){
			alert('Checkin failed');
			$btn.prop('disabled', false).text('Check In');
		});
});

// no-op: data is preloaded and bound via Rivets
