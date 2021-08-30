function MultiCustySelector(parent) {
 
  this.state = {
    starttime: '',
    endtime: '',
    activity: '',
    note: '',
    slots: [],
    num_slots: 1
  }

  this.bind_handlers([]);
  this.build_dom();

  this.mount(parent);
  this.load_styles();
  this.bind_dom();

}

MultiCustySelector.prototype = {
    constructor: MultiCustySelector,
}

Object.assign( MultiCustySelector.prototype, element);
Object.assign( MultiCustySelector.prototype, ev_channel); 

MultiCustySelector.prototype.HTML =  ES5Template(function(){/**
  <div class='multi_custy_selector'>
    <div class='attrib'># People</div>
              .value
                select.num_students rv-on-change='ctrl.set_num_slots'
                  option value="2" 2
                  option value="3" 3
                  option value="4" 4
                  option value="5" 5
                  option value="6" 6
            
            div rv-if='data.num_slots'
              hr
              .tuple rv-each-slot='data.rental.slots'
                .attrib
                  | Slot \#{index | fix_index}
                .value.edit rv-on-click='ctrl.choose_custy'
                  | {slot.customer_string}               
            hr
    </div>
  </div>
**/}).untab(2);

MultiCustySelector.prototype.CSS = ES5Template(function(){/**

**/}).untab(2);