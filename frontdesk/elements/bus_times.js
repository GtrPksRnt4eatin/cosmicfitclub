function BusTimes(el, attr) {
  this.state = {
    bus_times: {}
  }

  this.update();
  this.load_styles();
  this.bind_handlers(['update']);
  this.timer = this.setInterval(this.update, 20000);
}

BusTimes.prototype = {
  constructor: BusTimes,

  update() {
    $.get('/frontdesk/bus_times', function(resp) { 
        this.state.bus_times = resp;
      }.bind(this), 'json')
  }

}

Object.assign( BusTimes.prototype, element );

BusTimes.prototype.HTML = `
  <table>
    <tr class="tile">
      <td colspan="3"> Approaching B24 Busses </td>
    </tr>
    <tr class="tile" rv-each-bus="this.state.bus_times.south">
      <td class="minutes">
        <div> {bus.arrives_in} </div>
        <div> Minutes </div>
      </td>
      <td class="direction">
        <div> Southbound </div>
        <div> (L&G Train) </div>
      </td>
      <td class="arrival">
        { bus.arrival }
      </td>
    </tr>
    <tr class="tile" rv-each-bus="this.state.bus_times.north">
      <td class="minutes">
        <div> {bus.arrives_in} </div>
        <div> Minutes </div>
      </td>
      <td class="direction">
        <div> Northbound </div>
        <div> (7 Train) </div>
      </td>
      <td class="arrival">
        { bus.arrival }
      </td>
    </tr>
  </table>
`.untab(2);

BusTimes.prototype.CSS = `

  bus_times td         { padding: 0.2em 1em; }
  bus_times td.minutes { background: rgba(0,255,0,0.3); }

`.untab(2);

rivets.components['bus_times'] = {
  template:   function()        { return BusTimes.prototype.HTML },
  initialize: function(el,attr) { return new BusTimes(el,attr);  }
}