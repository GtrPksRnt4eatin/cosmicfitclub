$(document).ready(function() {
  rivets.bind(document.body, { data: data }); 

  $('#menu li').on('click', function(e) {
    window.location.href = e.target.getAttribute('href');
  });
});