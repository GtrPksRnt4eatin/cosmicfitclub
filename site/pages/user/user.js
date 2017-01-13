$(document).ready(function() {

  userview = new UserView( id('userview_container'));

  $('#logo').on('click', function(e) {
    window.location.href = '/';
  });

  $('#menu li').on('click', function(e) {
    window.location.href = e.target.getAttribute('href');
  });

});