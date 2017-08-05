function ReservationForm(parent) {

	this.state = {
      membership_status: { "plan": { "name": "None" } },
      class_passes: 0,
      reservation: {
      	customer_id: 0,
      	classdef_id: 0,
      	staff_id: 0,
      	
      }
      errors: []
	}

    rivets.formatters.zero_if_null   = function(val) { return empty(val) ? 0 : val; }
	rivets.formatters.has_membership = function(val) { return( empty(val) ? false : val.name != 'None' ); }

	this.bind_handlers(['load_customer', 'on_status']);
	this.build_dom(parent);
	this.load_styles();
	this.bind_dom();

}

ReservationForm.prototype = {
	constructor: ReservationForm,

	load_customer(id) {
	  if(id.target) { id = id.target.value; }
      $.get(`/models/customers/${parseInt(id)}/status`,  this.on_status, 'json');
	},

	on_status(data) { 
	  this.state.membership_plan = data.membership;
	  this.state.class_passes = data.passes;
	},

	set_reservation(reservation) {
		this.state.reservation = reservation;
	},

	validate_reservation() {
      this.state.errors = [];
      if( ! data.reservation.customer_id ) { data.reservation_errors.push("You must select a Customer"); }
      if( ! data.reservation.classdef_id ) { data.reservation_errors.push("You must select a Class");    }
      if( ! data.reservation.staff_id    ) { data.reservation_errors.push("You must select a Teacher");  }
      if( ! data.reservation.starttime   ) { data.reservation_errors.push("You must select a Timeslot"); }
      if( data.reservation_errors.length == 0 ) return true;
      $('#class_checkin_table').shake();
      return false;
    },

	reserve_membership(e,m) {

	},

	reserve_class_pass(e,m) {

	},

	reserve_paynow(e,m) {

	}
}

Object.assign( ReservationForm.prototype, element);
Object.assign( ReservationForm.prototype, ev_channel);

ReservationForm.prototype.HTML = `

  <div class='ReservationForm'>
    <button rv-on-click='this.reserve_membership' rv-enabled='state.membership_plan | has_membership'>
      Use Membership <br>
      ( { state.membership_plan.name } ) 
    </button>
    <button rv-on-click='this.reserve_class_pass' rv-enabled='state.class_passes | zero_if_null'>
      Use a Class Pass <br>
      ( { state.class_passes | zero_if_null } Remaining )
    </button>
    <button rv-on-click='this.reserve_paynow'>
      Pay $25 Now
    </button>
    <div class='errors'>
      <div rv-each-err='state.errors'>
        { err }
      </div>
    </div>
  </div>

`.untab(2);

ReservationForm.prototype.CSS = `

  .ReservationForm {
  	margin: 1em;
  }

  .ReservationForm button {
  	font-family: 'Industry-Light';
  	font-weight: bold;
  	height: 3em;
  	vertical-align: top;
  	width: 15em;
  	padding: .5em;
  	box-sizing: border-box;
  	font-size: 1em;
  	line-height: 1em;
  }

  .ReservationForm button:enabled {
  	cursor: pointer;
  }

`.untab(2);