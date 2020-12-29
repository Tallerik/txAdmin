var mode = "white";
var stor = window.localStorage;
window.addEventListener('load', function () {
    loadState()
})
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
        //document.getElementById("toggleLightBtn").innerHTML = '<i class="nav-icon icon-bulb"></i> Go to lightmode';
        changeCSS("css/dark.css", 0);
        mode = "dark";
        saveState()
    } else {
        //document.getElementById("toggleLightBtn").innerHTML = '<i class="nav-icon icon-bulb"></i> Go to darkmode';
        changeCSS("css/light.css", 0);
        mode = "white";
        saveState()
    }
    return false;
}

function saveState() {
    if(typeof(stor) === "undefined") {return;} // not supported
    stor.setItem("darkmode", mode);
}

function loadState() {
    if(typeof(stor) === "undefined") {return;} // not supported
    if(typeof(stor.getItem("darkmode")) === "undefined") {return;} // no data set
    mode = stor.getItem("darkmode")
    if( mode !== "white") {
        //document.getElementById("toggleLightBtn").innerHTML = '<i class="cid-sun"></i> Go to lightmode';
        changeCSS("css/dark.css", 0);
    }
}