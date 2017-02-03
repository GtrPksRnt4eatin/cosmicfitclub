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

  $('a.intent').on('click', function (e) {
    linkWithFallback($(this).data('scheme'), $(this).attr('href'));
  });

});

function linkWithFallback(uri, fallback) {
  var start, end, elapsed;
  start = new Date().getTime();
  document.location = uri;
  end = new Date.getTime();
  elapsed = (end - start);
  alert(elapsed);
  if(elapsed<1) window.open(fallback,'_blank');
}