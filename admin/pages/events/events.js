var data = {
  events: [],
  newevent: {}
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
    data['newevent'] = m.event;
  }

}

$(document).ready(function() {

  rivets.bind(document.body, { data: data, ctrl: ctrl } );
  rivets.formatters.dayofwk  = function(val) { return moment(val).format('ddd') };
  rivets.formatters.date     = function(val) { return moment(val).format('MMM Do') };
  rivets.formatters.time     = function(val) { return moment(val).format('h:mm a') };
  rivets.formatters.fulldate = function(val) { return moment(val).format('ddd MMM Do hh:mm a') };

  $('#menu li').on('click', function(e) { window.location.href = e.target.getAttribute('href'); });

  ctrl.get();

  id("newpic").onchange = function () {
    var reader = new FileReader();
    reader.onload = function (e) { id("newpreview").src = e.target.result; };
    reader.readAsDataURL(this.files[0]);
  };

  id('upload').onclick  = ctrl.add;

  flatpickr(".flatpickr", { enableTime: true } );
  
});
