ctrl = {

}

$(document).ready(function(){
  rivets.bind( document.body, { data: data, ctrl: ctrl } ); 
  var eventlist = new List('eventlist', { valueNames: [ 'time', 'name'] } );
});