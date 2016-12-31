$(document).ready(function() {

  $('#logo').on('click', function(e) {
    window.location.href = '/';
  });

  $('#menu li').on('click', function(e) {
    window.location.href = e.target.getAttribute('href');
  });

  schedule = new Schedule( id('schedule_container') );

});