$(document).ready(function() {
  const canvas = document.getElementById("canvas");
  const video = document.getElementById("video");
  const ctx = canvas.getContext("2d");
});

function readURL(input) {
    //THE METHOD THAT SHOULD SET THE VIDEO SOURCE
    if (input.files && input.files[0]) {
        var file = input.files[0];
        var url = URL.createObjectURL(file);
        console.log(url);
        var reader = new FileReader();
        reader.onload = function() {
            video.src = url;
            video.play();
        }
        reader.readAsDataURL(file);
    }
}