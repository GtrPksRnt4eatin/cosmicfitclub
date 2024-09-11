data = {
  dX: 0,
  dY: 0,
  dWidth: 1080,
  dHeight: 1350,
  urlText: "http://cosmicfitclub.com",
  textLines: "",
  opacity: 0.6
}

$(document).ready(function() {

  const canvas = document.getElementById("canvas");
  const video = document.getElementById("video");
  const ctx = canvas.getContext("2d");

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
      ctx.drawImage(video,data.dX,data.dY,data.dWidth,data.dHeight);
      lines = data.textLines.split("\n");
      maskHeight = 100 + (lines.length * 50);
      ctx.fillStyle = `rgb(0 0 0 / ${data.opacity}`;
      ctx.fillRect(0,1350-maskHeight, 1080, maskHeight);
      ctx.textAlign = "center";
      ctx.fillStyle = "white";
      ctx.font = "40pt Industry-Light";
      lines.reverse().forEach(function(line,index) {
        ctx.fillText(line, 540, 1250-(index*50))
      });
      frame.complete && ctx.drawImage(frame,0,0,1080,1350);     

      ctx.font = "40pt Industry-Bold";
      ctx.fillText(data.urlText, 540, 1325);
    }, 1000 / fps);
  }

  rivets.bind(document.body, { data: data } );

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