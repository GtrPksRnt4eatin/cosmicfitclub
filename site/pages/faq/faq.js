$(document).ready(function() {

  $('#logo').on('click', function(e) {
    window.location.href = '/';
  });

  $('#menu li').on('click', function(e) {
    window.location.href = e.target.getAttribute('href');
  });

  rivets.bind(document.body, { data: data }); 

});