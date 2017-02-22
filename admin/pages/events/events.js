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

  add_session: function(e,m) {
    data['newevent']['sessions'].push( data['newsession'] );
    data['newsession'] = {};
  }

}

$(document).ready(function() {

  rivets.formatters.dayofwk    = function(val) { return moment(val).format('ddd') };
  rivets.formatters.date       = function(val) { return moment(val).format('MMM Do') };
  rivets.formatters.time       = function(val) { return moment(val).format('h:mm a') };
  rivets.formatters.fulldate   = function(val) { return moment(val).format('ddd MMM Do hh:mm a') };
  rivets.formatters.simpledate = function(val) { return moment(val).format('MM/DD/YYYY hh:mm A') }; 
  
  rivets.binders['datefield'] = {
    bind: function(el) {
      this.flatpickrInstance = $(el).flatpickr({
        enableTime: true, 
        altInput: true, 
        altFormat: 'm/d/Y h:i K',
        onChange: function(val) {
          this.publish(val);
          if(this.el.onchange) { this.el.onchange(); }
        }.bind(this)
      })
    },
    unbind: function(el) {
      this.flatpickrInstance.destroy();
    },
    routine: function(el,value) {
      if(value) { 
        this.flatpickrInstance.setDate( value ); 
        this.flatpickrInstance.jumpToDate(value);
      }
    },
    getValue: function(el) {
      return el.value;
    }

  }

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  $('#menu li').on('click', function(e) { window.location.href = e.target.getAttribute('href'); });

  ctrl.get();

  id("newpic").onchange = function () {
    var reader = new FileReader();
    reader.onload = function (e) { id("newpreview").src = e.target.result; };
    reader.readAsDataURL(this.files[0]);
  };

  id('upload').onclick  = ctrl.add;

  id('session_start').onchange = function(e) {
    if(data.newsession.endtime == '') { data.newsession.endtime = this.value; }
    if(moment(data.newsession.endtime).isBefore(this.value)) { data.newsession.endtime = this.value; }
  };

});

function resolve(obj, path){
  var r=path.split(".");
  if(path){return resolve(obj[r.shift()], r.join("."));}
 return obj
}