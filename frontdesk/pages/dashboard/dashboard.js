data = {
  bus_times: {},
  current_time: "",
  checked: [true,true,true,true]
}

ctrl = {
  color_change(value) {
    data.checked[0] && $.post('/dmx/cmd', { index: 0, capability: "color", value: value.hexString });
    data.checked[1] && $.post('/dmx/cmd', { index: 1, capability: "color", value: value.hexString });
    data.checked[2] && $.post('/dmx/cmd', { index: 2, capability: "color", value: value.hexString });
    data.checked[3] && $.post('/dmx/cmd', { index: 3, capability: "color", value: value.hexString });
  },

  show_spider1() {
    dmx_sliders.load_device(4);
    dmx_sliders.show();
  },

  show_spider2() {
    dmx_sliders.load_device(5);
    dmx_sliders.show();
  }
}


function debounce(func, delay) {
  let timeoutId;
  busy = false;
  next_val = null;

  return function(...args) {
    if(busy) { next_val = args; return; }
    if(!busy) {
      busy = true;
      func.apply(this, args);
      timer = setInterval(function() { 
        if(next_val) { func.apply(this, next_val); next_val = null; }
        else { busy = false; clearInterval(timer); }
      },300);
    }
  };
}

$(document).ready( function() { 
  updateClock();
  getBusTimes();
  colorPicker = new iro.ColorPicker('#picker');
  colorPicker.on('color:change', debounce(ctrl.color_change,1000));

  var view = rivets.bind( $('body'), { data: data, ctrl: ctrl } );
  dmx_sliders = new DmxSliders();
  popupmenu   = new PopupMenu( id('popupmenu_container') );
  dmx_sliders.ev_sub('show', popupmenu.show );
  calendar = get_element(view, 'loft-calendar');
  setInterval(updateClock,     1000);
  setInterval(getBusTimes,    20000);
  setInterval(updateCalendar, 120000);
});

function updateClock() {
  data.current_time = new Date().toLocaleString('en-US', { hour: 'numeric', minute: 'numeric', hour12: true });
}

function updateCalendar() {
  calendar.full_refresh();
}

function getBusTimes() {
  $.get('/frontdesk/bus_times', function(resp) { 
    data.bus_times = resp;
  }, 'json')
}