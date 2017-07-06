data = {
	transactions: {
		pass_transactions: [],
		membership_uses: []
	}
    
}

$(document).ready( function() {

    $('#customers').chosen();
    $('#customers').on('change', get_customer_data);

    rivets.bind( 'body', { data: data } );

});

function get_customer_data() {
    var id = $('#customers').value();
    $.get(`/models/customers/${id}/transaction_history`, function(resp) { data.transactions = resp; } , 'json')
}