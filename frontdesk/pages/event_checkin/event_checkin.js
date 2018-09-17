ctrl = {

  open_event: function(e,m) {
  	location.href = `event_attendance/${m.event.id}`;
  },

  filter: function(e,m) {
    searchstring = e.target.value;
  	data['filtered'] = data['events'].filter( function(val) {
      return val.name.match(new RegExp(searchstring, "i") ) ? true : false; 
    });
  }

}

$(document).ready(function(){
  
  userview = new UserView(id('userview_container'));
  
  setup_bindings();

  //var eventlist = new List('eventlist', { valueNames: [ 'time', 'name'] } );
  get_data();

});

function get_data() {
  $.get('/models/event/list', function(list) { data['events'] = list; } );
}

function setup_bindings() {
  include_rivets_dates();
  rivets.bind( document.body, { data: data, ctrl: ctrl } ); 
}