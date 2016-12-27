$(document).ready(function() {
  $('#menu li').on('click', function(e) {
    window.location.href = e.target.getAttribute('href');
  });
});