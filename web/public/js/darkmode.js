var mode = "white"

function changeCSS(cssFile, cssLinkIndex) {

    var oldlink = document.getElementsByTagName("link").item(cssLinkIndex);

    var newlink = document.createElement("link");
    newlink.setAttribute("rel", "stylesheet");
    newlink.setAttribute("type", "text/css");
    newlink.setAttribute("href", cssFile);

    document.getElementsByTagName("head").item(0).replaceChild(newlink, oldlink);
}

function toggleLightMode() {
    if(mode === "white") {
        document.getElementById("toggleLightBtn").innerHTML = '<i class="cid-sun"></i> Go to lightmode';
        changeCSS("css/dark.css", 0)
        mode = "dark"

    } else {
        document.getElementById("toggleLightBtn").innerHTML = '<i class="cid-moon"></i> Go to darkmode';
        changeCSS("css/light.css", 0)
        mode = "white"
    }
}
