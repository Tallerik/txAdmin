const imagecount = 10;


function loadImages() {
    let src = "img/default_avatar_";
    src = src + (Math.floor(Math.random() * imagecount) + 1).toString() + ".png";
    document.getElementById("profile_image1").src = src;
    document.getElementById("profile_image2").src = src;
}