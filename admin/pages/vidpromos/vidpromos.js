$(document).ready(function() {

  const canvas = document.getElementById("canvas");
  const video = document.getElementById("video");
  const ctx = canvas.getContext("2d");

  canvasInterval = 0; 
  fps = 60;

  video.onpause = function() { clearInterval(canvasInterval); }
  video.onended = function() { clearInterval(canvasInterval); }
  video.onplay  = function() { 
    clearInterval(canvasInterval);
    let frame = new Image();
    frame.src = "/vidpromo_bg.png"
    canvasInterval = window.setInterval(() => {
      ctx.drawImage(video,0,0,1080,1350);
      frame.complete && ctx.drawImage(frame,0,0,1080,1350);
    }, 1000 / fps);
  }

});

function readURL(input) {
    //THE METHOD THAT SHOULD SET THE VIDEO SOURCE
    if (input.files && input.files[0]) {
        var file = input.files[0];
        var url = URL.createObjectURL(file);
        var reader = new FileReader();
        reader.onload = function() {
            video.src = url;
            video.play();
        }
        reader.readAsDataURL(file);
    }
}