$(document).ready(function(){
  fetch_image();
  $('#doorcam').load(function(){ 
    $('#doorcam').attr('src', "http://cosmicfitclub.ddns.net:5051/cgi-bin/jpeg?" + Math.random() );
  })
})

function fetch_image() {
  $.ajax({
    type: "GET",
    url: "https://cosmicfitclub.ddns.net:5051/cgi-bin/camera",
    headers: { "Authorization": "Basic " + btoa("admin:12345") },
    success: function (data){ console.log(data); fetch_image(); }
  });
}