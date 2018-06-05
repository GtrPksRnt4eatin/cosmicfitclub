$(document).ready(function(){
  $('#doorcam').load(function(){ 
    $('#doorcam').attr('src', "http://cosmicfitclub.ddns.net:5051/cgi-bin/jpeg?" + Math.random() );
  })
})