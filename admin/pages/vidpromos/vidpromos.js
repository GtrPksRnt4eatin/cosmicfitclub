$(document).ready(function() {

  const canvas = document.getElementById("canvas");
  const video = document.getElementById("video");
  const ctx = canvas.getContext("2d");

  dX = 0;
  dY = 0;
  dWidth = 1080;
  dHeight = 1350;
  urlText = "http://cosmicfitclub.com"

  canvasInterval = 0; 
  fps = 60;

  let frame = new Image();
  frame.src = "/vidpromo_bg.png"
  frame.onload = function() { ctx.drawImage(frame,0,0,1080,1350); }

  video.onpause = function() { clearInterval(canvasInterval); }
  video.onended = function() { clearInterval(canvasInterval); }
  video.onplay  = function() { 
    clearInterval(canvasInterval);
    canvasInterval = window.setInterval(() => {
      ctx.drawImage(video,dX,dY,dWidth,dHeight);
      frame.complete && ctx.drawImage(frame,0,0,1080,1350);
      ctx.textAlign = "center";
      ctx.fillStyle = "white";
      ctx.font = "48pt Industry-Bold"
      ctx.fillText(urlText, 640, 1250);
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