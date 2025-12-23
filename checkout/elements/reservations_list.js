function ReservationsList(parent,attr) {
    rivets.formatters.empty = function(reservations) { return reservations ? reservations.length == 0 : true; }
    
    rivets.formatters.passes_total = function(reservations) {
      return reservations ? reservations.reduce( (total, reservation) => total + reservation.passes, 0 ) : 0;
    }
    
    this.bind_handlers(['cancel', 'buy_passes']);
    this.load_styles();
}

ReservationsList.prototype = {
  constructor: ReservationsList,
  cancel: function(e,m) {
    if(!confirm("Are you sure you want to cancel?")) { return; }
    $.del(`/models/groups/${m.reservation.id}`)
    .done(function() { window.location.reload(); });
  },
  buy_passes: function(e,m) {
    const button = e.target;
    const pack_id = button.getAttribute('data-id');
    const name = button.getAttribute('data-name');
    const amount = parseInt(button.getAttribute('data-amount'));
    
    this.ev_fire('buy_passes', { pack_id: pack_id, name: name, amount: amount });
  }
}

Object.assign( ReservationsList.prototype, element);
Object.assign( ReservationsList.prototype, ev_channel);

ReservationsList.prototype.HTML = `
  <div rv-hide='reservations | empty'>
    <table class='upcoming'>
      <tr>
        <td colspan='2'>Your Upcoming Reservations:</td>
      </tr>
      <tr rv-each-reservation='reservations'>
        <td>{ reservation.summary }</td>
        <td class='cancel' rv-on-click='cancel'>Cancel</td>
      </tr>
    </table>

    <div class='buy_passes'>
      These Reservations will require a total of { reservations | passes_total } passes </br>
      You currently have { passes } passes
      <div>
        <h2>Would you like to buy more?</h2>
        <button class='buy-button' data-id='21' data-name='1 Hr Pass' data-amount='1200' rv-on-click='buy_passes'>1 Hr Pass</button>
        <button class='buy-button' data-id='34' data-name='90 Min Pass' data-amount='1800' rv-on-click='buy_passes'>90 Min Pass</button>
        <button class='buy-button' data-id='17' data-name='2 Hr Pass' data-amount='2400' rv-on-click='buy_passes'>2 Hr Pass</button>
        <button class='buy-button' data-id='25' data-name='20 Hr Package' data-amount='20000' rv-on-click='buy_passes'>20 Hr Package</button>
      </div>
    </div>
  </div>
`.untab(2);

ReservationsList.prototype.CSS = `
  reservations-list {
    display: inline-block;
  }

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

  reservations-list .buy_passes button.buy-button {
    font-size: 0.8em;
    box-shadow: 0 0 0.5em white inset, 0 0 0.5em rgb(50, 50, 50);
    padding: 0.5em 0.75em;
    border-radius: 0.75em;
    cursor: pointer;
    display: inline-block;
    margin: 0.25em;
    line-height: 1.5em;
    background: transparent;
    border: none;
    color: inherit;
    font-family: inherit;
  }

  reservations-list .buy_passes button.buy-button:hover {
    background: rgba(255,255,255,0.1);
  }

  reservations-list .buy_passes button.buy-button:active {
    background: rgba(255,255,255,0.2);
  }
`.untab(2);

rivets.components['reservations-list'] = {
  template:  function()         { return ReservationsList.prototype.HTML; },
  initialize: function(el,attr) { return new ReservationsList(el,attr);   }
}
