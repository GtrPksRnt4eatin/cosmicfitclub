var data = {

  events: [],

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
    $.get('/models/events', function(events) {
      data.events = JSON.parse(events);
    });
  },
  
  add: function(e) {
    var data = new FormData( id('new') );
    var request = new XMLHttpRequest();
    request.open("POST", "/models/events");
    request.send(data);
    ctrl.get();
  },  

  del: function(e,m) {
    $.del(`/models/events/${m.event.id}`, function() {
      data.events.splice( data.events.indexOf( m.event ), 1 );
    });
  },

  edit: function(e,m) {
    location.href = `events/${m.event.id}`;
  },

  list: function(e,m) {
    location.href = `events/${m.event.id}/checkin`;
  },

  add_session: function(e,m) {
    data['newevent']['sessions'].push( data['newsession'] );
    data['newsession'] = {};
  }

}

$(document).ready(function() {

  include_rivets_dates();

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  ctrl.get();

  //id("newpic").onchange = function () {
  //  var reader = new FileReader();
  //  reader.onload = function (e) { id("newpreview").src = e.target.result; };
  //  reader.readAsDataURL(this.files[0]);
  //};

  id('new2').onclick = function(e) {
    $.post('/models/events', JSON.stringify( { id: 0 } ) )
      .done( function(resp) { 
        window.location = `events/${JSON.parse(resp).id}` 
      }) 
  };

  //id('session_start').onchange = function(e) {
  //  if(data.newsession.endtime == '') { data.newsession.endtime = this.value; }
  //  if(moment(data.newsession.endtime).isBefore(this.value)) { data.newsession.endtime = this.value; }
  //};

});

function resolve(obj, path){
  var r=path.split(".");
  if(path){return resolve(obj[r.shift()], r.join("."));}
 return obj
}