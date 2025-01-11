function BusTimes(el, attr) {
  this.state = {
    bus_times: {},
    current_time: ""
  }

  this.state.mta = !!attr['mta'];

  this.update();
  this.load_styles();
  this.bind_handlers(['update', 'update_clock']);
  this.timer = setInterval(this.update, 20000);
  this.clock = setInterval(this.update_clock, 1000);
}

BusTimes.prototype = {
  constructor: BusTimes,

  update() {
    $.get('/frontdesk/bus_times', function(resp) { 
        this.state.bus_times = resp;
      }.bind(this), 'json')
  },

  update_clock() {
    this.state.current_time = new Date().toLocaleString('en-US', { hour: 'numeric', minute: 'numeric', hour12: true });
  }

}

Object.assign( BusTimes.prototype, element );

BusTimes.prototype.HTML = `
  <div class="mta" rv-if="state.mta">
    <div class="heading">
      <img src="mta_logo.png" />
      <span class='welcome'>Welcome to Meeker Av/Kingsland Av</span>
      <span class='time'>{state.current_time}<span>
    </div>
    <table>
      <tr class="bluerow">
        <td>Next Bus</td>
        <td>Towards</td>
        <td>Status</td>
      </tr>
      <tr rv-each-bus="state.bus_times.south">
        <td>B24 {bus.arrival}</td>
        <td>Graham Av&nbsp;<img class="subway" src="l.svg"/><img class="subway" src="g2.svg"/></td>
        <td>{bus.arrives_in} min</td>
      </tr>
      <tr rv-unless="state.bus_times.south.0">
        <td colspan="3">No Buses En Route To This Stop</td>
      </tr>
    </table>
  </div>

  <table rv-unless="state.mta">
    <tr class="tile">
      <td colspan="3"> Approaching B24 Busses </td>
    </tr>
    <tr class="tile" rv-each-bus="state.bus_times.south">
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
    <tr class="tile" rv-each-bus="state.bus_times.north">
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

  bus-times .mta { 
    font-family: 'nimbus_sans';
    background: black;
    color: white;
    text-align: left;
    padding-bottom: 5em;
  }

  bus-times .mta .heading {
    font-size: 2em;
    font-weight: bold;
    padding: 0.5em 0.5em 2em;
    display: flex;
  }

  bus-times .mta .heading .welcome{
    flex: 1;
    padding-left: 0.5em;
  }

  bus-times table {
    display: table;
    width: 100%;
    font-size: 1em;
  }

  bus-times .mta table {
    border-collapse: collapse;
    width: 100%;
  }

  bus-times .mta table .bluerow {
    background: #4578ad; 
  }

  bus-times .mta img {
    height: 1.25em;
  }

  bus-times .mta img.subway {
    vertical-align: text-top;
    padding: none;
  }

  bus-times .mta td { 
    font-size: 1.5em; 
    padding: 0.5em 1em; 
  }

  bus-times td         { padding: 0.2em 1em; }
  bus-times td.minutes { background: rgba(0,255,0,0.3); }

`.untab(2);

rivets.components['bus-times'] = {
  template:   function()        { return BusTimes.prototype.HTML },
  initialize: function(el,attr) { return new BusTimes(el,attr);  }
}