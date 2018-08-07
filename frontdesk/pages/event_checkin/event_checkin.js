ctrl = {

}

$(document).ready(function(){
  
  userview = new UserView(id('userview_container'));
  
  setup_bindings();

  //var eventlist = new List('eventlist', { valueNames: [ 'time', 'name'] } );
  
});

function setup_bindings() {
  include_rivets_dates();
  rivets.bind( document.body, { data: data, ctrl: ctrl } ); 
}