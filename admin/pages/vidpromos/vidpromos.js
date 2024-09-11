data = {
  dX: 0,
  dY: 0,
  dWidth: 1080,
  dHeight: 1350,
  urlText: "http://cosmicfitclub.com",
  textLines: "",
  opacity: 0.6,
  chunks: []
}

ctrl = {
}

$(document).ready(function() {

  canvas = document.getElementById("canvas");
  video = document.getElementById("video");
  ctx = canvas.getContext("2d");

  stream = canvas.captureStream(60);
  recorder = new MediaRecorder(stream);

  canvasInterval = 0; 
  fps = 60;

  let frame = new Image();
  frame.src = "/vidpromo_bg.png"
  frame.onload = function() { ctx.drawImage(frame,0,0,1080,1350); }

  video.onpause = function() { clearInterval(canvasInterval); }
  video.onended = function() { 
    clearInterval(canvasInterval); 
    if(recorder.state == 'recording') { recorder.stop(); }
  }
  video.onplay  = function() { 
    clearInterval(canvasInterval);
    canvasInterval = window.setInterval(() => {
      ctx.drawImage(video,data.dX,data.dY,data.dWidth,data.dHeight);
      lines = data.textLines.split("\n");
      if(lines.length>0) {
        maskHeight = 150 + (lines.length * 55);
        ctx.fillStyle = `rgb(0 0 0 / ${data.opacity}`;
        ctx.fillRect(0,1350-maskHeight, 1080, maskHeight);
        ctx.textAlign = "center";
        ctx.fillStyle = "white";
        ctx.font = "40px Industry-Medium";
        lines.reverse().forEach(function(line,index) {
          if(index == lines.length-1) { ctx.font = "40px Industry-Bold"; }
          ctx.fillText(line, 540, 1200-(index*55))
        });
      }
      frame.complete && ctx.drawImage(frame,0,0,1080,1350);
      ctx.font = "40px Industry-Bold";
      ctx.fillText(data.urlText, 540, 1325);
    }, 1000 / fps);
  }

  recorder.ondataavailable = function(e) { data.chunks.push(e.data); }
  recorder.onstop = function(e) {
    let blob = new Blob(data.chunks, { 'type': 'video/mp4' });
    let blobUrl = URL.createObjectURL(blob);
    var link = document.createElement("a");
    link.href = blobUrl;
    link.download = "Promo.mp4";
    $("body").append(link);
    link.click();
    window.URL.revokeObjectURL(url);
    link.remove();
    data.chunks = [];
  }

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

});

function readURL(input) {
    //THE METHOD THAT SHOULD SET THE VIDEO SOURCE
    video.setAttribute("loop", true);
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

function record() {
    video.removeAttribute("loop");
    video.pause();
    video.currentTime = 0;
    video.load();
    video.play();
    stream.addTrack(video.captureStream().getAudioTracks()[0])
    recorder.start();
  }