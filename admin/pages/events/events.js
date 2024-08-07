var data = {

  events: [],
  past_events: [],

  newevent: {
    sessions: [],
    prices: []
  },

  newsession: {
    starttime: '',
    endtime: '',
    title: '',
    description: ''
  },

  newprice: {
    title: '',
    included_sessions: [],
    member_price: 0,
    full_price: 0
  }

}

var ctrl = {

  get: function() {
    $.get('/models/events/future_all', function(events) { data.events      = events; }, 'json');
    $.get('/models/events/past',       function(events) { data.past_events = events; }, 'json');
  },
  
  add: function(e) {
    var data = new FormData( id('new') );
    var request = new XMLHttpRequest();
    request.open("POST", "/models/events");
    request.send(data);
    ctrl.get();
  },  

  del: function(e,m) {
    $.del(`/models/events/${m.data.event_id}`)
     .success(function() { data.events.splice( data.events.indexOf( m.data.event ), 1 ); })
     .fail(function(xhr) { 
        alert(xhr.responseText);
     });
  },

  edit: function(e,m) {
    location.href = `events/${m.event.id}`;
  },

  list: function(e,m) {
    location.href = `/frontdesk/event_attendance/${m.event.id}`;
  },

  add_session: function(e,m) {
    data['newevent']['sessions'].push( data['newsession'] );
    data['newsession'] = {};
  }

}

$(document).ready(function() {

  include_rivets_dates();

  rivets.formatters.empty = function(val) { return(val ? val.length == 0 : false);}

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  ctrl.get();

  id('new2').onclick = function(e) {
    var name = window.prompt("Enter Event Title","");
    $.post('/models/events', { id: 0, name: name } )
     .done( function(resp) { window.location = "events/" + resp.id } ); 
  };

});

function resolve(obj, path){
  var r=path.split(".");
  if(path){return resolve(obj[r.shift()], r.join("."));}
 return obj
}
