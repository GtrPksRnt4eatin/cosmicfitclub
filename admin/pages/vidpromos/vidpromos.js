data = {
  dX: 0,
  dY: 0,
  dWidth: 1080,
  dHeight: 1350,
  urlText: "http://cosmicfitclub.com",
  textLines: "",
  opacity: 0.6,
  chunks: [],
  canvas_width: 1080,
  canvas_height: 1350,
  frame_url: "/vidpromo_bg.png"

}

ctrl = {
}

$(document).ready(function() {

  const params = new URLSearchParams(window.location.search);
  if(params.has('story')) {
    data.canvas_height = 1920;
    data.frame_url = '/vidpromo_story.png'
  }

  canvas = document.getElementById("canvas");
  video = document.getElementById("video");
  ctx = canvas.getContext("2d");

  stream = canvas.captureStream(60);
  recorder = new MediaRecorder(stream, { videoBitsPerSecond: 4000000 });

  canvasInterval = 0; 
  fps = 40;

  let frame = new Image();
  frame.src = data.frame_url;
  frame.onload = function() { ctx.drawImage(frame,0,0,data.canvas_width,data.canvas_height); }

  video.onpause = function() { clearInterval(canvasInterval); }
  video.onended = function() { 
    clearInterval(canvasInterval); 
    if(recorder.state == 'recording') { recorder.stop(); }
  }
  
  video.onloadeddata = function() {
    track = (video.mozCaptureStream ? video.mozCaptureStream() : video.captureStream()).getAudioTracks()[0];
    track.applyConstraints({
      echoCancellation: false,
      autoGainControl: false,
      noiseSuppression: false
    });
    stream.addTrack(track)
  }

  video.onplay  = function() { 
    clearInterval(canvasInterval);
    canvasInterval = window.setInterval(() => {
      ctx.drawImage(video,data.dX,data.dY,data.dWidth,data.dHeight);
      lines = data.textLines.split("\n");
      if(lines.length>0) {
        maskHeight = 150 + (lines.length * 55);
        ctx.fillStyle = `rgb(0 0 0 / ${data.opacity}`;
        ctx.fillRect(0,data.canvas_height-maskHeight, 1080, maskHeight);
        ctx.textAlign = "center";
        ctx.fillStyle = "white";
        ctx.font = "40px Industry-Medium";
        lines.reverse().forEach(function(line,index) {
          if(index == lines.length-1) { ctx.font = "40px Industry-Bold"; }
          ctx.fillText(line, 540, data.canvas_height-150-(index*55))
        });
      }
      frame.complete && ctx.drawImage(frame,0,0,data.canvas_width,data.canvas_height);
      ctx.font = "40px Industry-Bold";
      ctx.fillText(data.urlText, 540, data.canvas_height-25);
    }, 1000 / fps);
  }

  recorder.ondataavailable = function(e) { data.chunks.push(e.data); }
  recorder.onstop = function(e) {
    let buggyBlob = new Blob(data.chunks, { 'type': 'video/webm' });
    ysFixWebmDuration(buggyBlob, video.duration*1000, function(blob) {
      let blobUrl = URL.createObjectURL(blob);
      var link = document.createElement("a");
      link.href = blobUrl;
      link.download = "Promo.webm";
      $("body").append(link);
      link.click();
      window.URL.revokeObjectURL(blobUrl);
      link.remove();
      data.chunks = [];
    })   
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
    video.play();
    recorder.start();
  }