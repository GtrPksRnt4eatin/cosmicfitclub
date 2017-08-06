function ReservationForm(parent) {

	this.state = {
      membership_plan: { "id": 0, "name": "None" },
      class_passes: 0,
      occurrence: {
      },
      reservation: {
      	customer_id: 0,
      	classdef_id: 0,
      	staff_id: 0,    
        starttime: null	
      },
      errors: []
	}

  rivets.formatters.zero_if_null   = function(val) { return empty(val) ? 0 : val; }
	rivets.formatters.has_membership = function(val) { return( empty(val) ? false : val.name != 'None' ); }

	this.bind_handlers(['load_customer', 'refresh_customer', 'on_customer', 'reserve_membership', 'reserve_class_pass', 'reserve_paynow', 'after_reservation', 'after_paynow']);
	this.build_dom(parent);
	this.load_styles();
	this.bind_dom();

}

ReservationForm.prototype = {
	constructor: ReservationForm,

	load_customer(id) {
	  if(id.target) { id = id.target.value; }
    this.state.reservation.customer_id = id;
    $.get(`/models/customers/${parseInt(id)}/status`,  this.on_customer, 'json');
	},

  refresh_customer() {
    this.load_customer(this.state.reservation.customer_id);
  },

	on_customer(data) { 
	  this.state.membership_plan = data.membership;
	  this.state.class_passes = data.passes;
	},

  clear_customer() {
    this.state.reservation.customer_id = 0;
    this.state.membership_plan = { "id": 0, "name": "None" };
    this.state.class_passes = 0;
  },

	set_reservation(reservation) {
		this.state.reservation = reservation;
	},

  set_occurrence(occurrence) {
    this.state.occurrence = occurrence;
    this.state.reservation.classdef_id = occurrence.classdef_id;
    this.state.reservation.staff_id    = occurrence.staff_id;
    this.state.reservation.starttime   = occurrence.starttime;
  },

	validate_reservation() {
      this.state.errors = [];
      if( ! this.state.reservation.customer_id ) { this.state.errors.push("You must select a Customer"); }
      if( ! this.state.reservation.classdef_id ) { this.state.errors.push("You must select a Class");    }
      if( ! this.state.reservation.staff_id    ) { this.state.errors.push("You must select a Teacher");  }
      if( ! this.state.reservation.starttime   ) { this.state.errors.push("You must select a Timeslot"); }
      if( this.state.errors.length == 0 ) return true;
      $(this.dom).shake();
      return false;
    },

	reserve_membership(e,m) {
    if( ! this.validate_reservation() ) return;
    this.post_reservation("membership");
	},

	reserve_class_pass(e,m) {
    if( ! this.validate_reservation() ) return; 
    this.post_reservation("class_pass");
	},

	reserve_paynow(e,m) {
    if( ! this.validate_reservation() ) { return; }
    classname = this.state.occurrence.classdef.name;
    teachername = this.state.occurrence.teacher.name;
    reason = `${classname} w/ ${teachername} - ${moment(this.state.occurrence.starttime).format('ddd MMM D @ h:mm a')}`;
    this.ev_fire('paynow', [ this.state.reservation.customer_id, 2500, reason, null, this.after_paynow ]);
	},

  after_paynow(payment_id) {
    this.state.reservation.payment_id = payment_id;
    this.post_reservation("payment");
  },
 
  post_reservation(type) {
    this.state.reservation.transaction_type = type;
    $.post('/models/classdefs/reservation', this.state.reservation)
     .done( this.after_reservation )
     .fail( function(e) { alert('reservation failed!'); });
  },

  after_reservation() {
    this.refresh_customer();
    this.ev_fire('reservation_made');
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

  .ReservationForm .errors {
    padding: .5em;
  }

  .ReservationForm .errors div {
    color: red;
    font-size: .8em;
  }

`.untab(2);