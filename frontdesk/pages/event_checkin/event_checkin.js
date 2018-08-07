ctrl = {

}

$(document).ready(function(){
  
  userview = new UserView(id('userview_container'));

  rivets.bind( document.body, { data: data, ctrl: ctrl } ); 
  
  //var eventlist = new List('eventlist', { valueNames: [ 'time', 'name'] } );
});