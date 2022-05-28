function CheckoutPrivates() {

	this.state = {

	}

	this.bind_handlers([]);
	this.build_dom();
	this.load_styles();
	this.bind_dom();

}

CheckoutPrivates.prototype = {
	constructor: CheckoutPrivates
}

Object.assign( CheckoutPrivates.prototype, element);
Object.assign( CheckoutPrivates.prototype, ev_channel);

CheckoutPrivates.prototype.HTML = `
  
  <div class='checkout_privates'>

    <hr class='mobile' width='75%' />
    <br class='mobile'/>

    <div rv-unless='state.selected_timeslot.starttime'>
      <h2>Choose Available Sessions:</h3><br/>

      <div id='daypilot'/>

      <table class='included_sess' rv-unless="state.included_sessions | sess_empty">
        <tr>
          <td colspan='3'>Selected Sessions:</td>
        <tr rv-each-sess='state.included_sessions | populate_sess'>
          <td>{ sess.start_time | shortdt }</td>
          <td>{ sess.title }</td>
          <td>{ sess.individual_price_full | money }
        </tr>
      </table>
    </div>

    <div rv-if='state.selected_timeslot.starttime'>
      <div class='selected_timeslot'>
        <h2>{ state.selected_timeslot.starttime | fulldate } - { state.selected_timeslot.endtime | time }</h2>
        <span class='clear_timeslot' rv-on-click='this.clear_timeslot'>change timeslot</span>
        <br/><br/>
      </div>

      <div class='tuple'>
        <div class='attrib'># People</div>
        <div class='value'>
          <select class='num_students' rv-on-change='this.set_num_slots'>
            <option value='1'>1</option>
            <option value='2'>2</option>
          </select>
        </div>
      </div>
    
      <div rv-if='state.num_slots'>
        <hr/>
        <div class='tuple' rv-each-slot='state.rental.slots'>
          <div class='attrib'>Slot #{ index | fix_index }</div>
          <div class='value edit' rv-on-click='this.choose_custy'>{slot.customer_string}</div>
        </div>
      </div>

      <hr/>
    </div>

    <div>
      <button id='checkout' rv-on-click='this.checkout_new'> Pay { state.total_price | money } Now</button>
    </div>

  </div>
  
`.untab(2);

CheckoutPrivates.prototype.CSS = `

  .checkout_privates .clear_timeslot {
    cursor: pointer;
    color: #9999FF;
  }

`.untab(2);