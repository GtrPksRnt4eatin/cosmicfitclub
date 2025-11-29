function ReservationsList() {

	this.state = {

	}

	this.bind_handlers([]);
	this.build_dom();
	this.load_styles();
	this.bind_dom();

}

ReservationsList.prototype = {
	constructor: ReservationsList
}

Object.assign( ReservationsList.prototype, element);
Object.assign( ReservationsList.prototype, ev_channel);

ReservationsList.prototype.HTML = `
  <div class='tile' rv-show='state.my_reservations>
    <table class='upcoming'>
      <tr>
        <td colspan='2'>Your Upcoming Reservations:</td>
      </tr>
      <tr rv-each-reservation='state.my_reservations'>
        <td>{ reservation.summary }</td>
        <td class='cancel' rv-on-click='cancel'>Cancel</td>
      </tr>
    </table>

    <div class='buy_passes'>
      These Reservations will require a total of { state.my_reservations | passes_total } passes </br>
      You currently have { state.class_passes } passes
      <div>
        <h2>Would you like to buy more?</h2>
        <a href='/checkout/pack/21'>1 Hr Pass</a>
        <a href='/checkout/pack/34'>90 Min Pass</a>
        <a href='/checkout/pack/17'>2 Hr Pass</a>
        <a href='/checkout/pack/25'>20 Hr Package</a>
      </div>
    </div>
  </div>
`.untab(2);

ReservationsList.prototype.CSS = `
  reservations-list table.upcoming {
    border-spacing: 0.5em; 
    border-radius: 0.5em;
    background: rgba(0,0,0,0.2);
  }
  
  reservations-list table.upcoming td {
    border-radius: 0.25em;
    background:rgba(255,255,255,0.2);
    padding: 0.25em 0.5em;
  }
    
  reservations-list table.upcoming td.cancel {
    background: rgba(255,100,100,0.5);
    color: white;
    cursor: pointer;
  }

  reservations-list .buy_passes a {
    font-size: 0.8em;
    box-shadow: 0 0 0.5em white inset, 0 0 0.5em rgb(50, 50, 50);
    padding: 0.5em 0.75em;
    border-radius: 0.75em;
    cursor: pointer;
    display: inline-block;
    text-decoration: none;
    margin: 0.25em;
    line-height: 1.5em;
  }
`.untab(2);

rivets.components['reservations-list'] = {
  template:  function()         { return ReservationsList.prototype.HTML; },
  initialize: function(el,attr) { return new ReservationsList(el,attr);   }
}
