$(document).ready(function() {
  pad = $("#signaturepad").jSignature()

  id('submit').addEventListener('click', function() {
    $.post('/waiver', pad.jSignature("getData", "svg")[1] );
  })
});