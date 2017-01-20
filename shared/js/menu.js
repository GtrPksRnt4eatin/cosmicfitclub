$(document).ready(function() {

  $('#logo').on('click', function(e) {
    window.location.href = '/';
  });

  $('.menubtn').on('click', function(e) {
    $('ul#menu').toggle();
    $('#userview_container').toggle();
  });

  $('#menu li').on('click', function(e) {
    window.location.href = e.target.getAttribute('href');
  });

  userview = new UserView( id('userview_container'));

});