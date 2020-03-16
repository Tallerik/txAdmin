//Requires
const webUtils = require('./webUtils.js');
const clone = require('clone');
const context = 'WebServer:extensions_playerlist';


/**
 * Returns the output page containing the live console
 * @param {object} res
 * @param {object} req
 */
module.exports = async function action(res, req) {
    //Check permissions
    if(!webUtils.checkPermission(req, 'console.view', context)){
        let out = await webUtils.renderMasterView('basic/generic', req.session, {message: `You don't have permission to view this page.`});
        return res.send(out);
    }
    let players = clone(globals.monitor.statusServer.players);
    let rowstart = "<div class=\"row\">";
    let rowend = "</div>";
    let card = "<div class=\"col-sm-6\"><div class=\"card card-accent-secondary m-1\">\n" +
        "            <div class=\"card-header font-weight-bold\">{{HEADER}}</div>\n" +
        "            <div class=\"card-body\">\n" +
        "{{BODY}}" +
        "            </div>\n" +
        "        </div></div>";

    let playerHtml;
    let i = 0;
    playerHtml = rowstart;
    players.forEach(player => {
        playerHtml = playerHtml + card.replace("{{HEADER}}", player.name).replace("{{BODY}}", getCardContent(player));
        i++;
        if (i == 2) {
            playerHtml = playerHtml + rowend;
            i = 0;
        }
    });
    if(i != 0) {
        playerHtml = playerHtml + rowend;
    }
    let renderData = {
        headerTitle: 'Playerlist',
        players: playerHtml
    }

    let out = await webUtils.renderMasterView('playerlist', req.session, renderData);
    return res.send(out);
};


function getCardContent(p) {
    let out = "";
    let breakhtml = "</br>";
    let boldin = "<b>";
    let boldout = "</b>";
    let discordTag = ""
    if(hasDiscord(p.identifiers)) {
        let dcuserpromise = globals.discordBot.client.users.fetch(p.identifiers.discord.replace("discord:", ""));
        let dcuser = null;
        let dcpic = null;
        dcuserpromise.then(user => {
            dcuser = user;
        })
        if(dcuser != null) {
            dcpic = "https://cdn.discordapp.com/avatars/" + p.identifiers.discord.replace("discord:", "") + "/" + dcuser.avatar + ".png"

            discordTag = "<div style='width: 99%; margin-left: auto; margin-right: auto;' class='p-1 rounded'>" +
                "<div class='row'><div class='col-2'><img class='rounded-circle m-1' src=" + dcpic + "></div>" +
                "<div class='col-8'><b>" + dcuser.tag + "</b><br><small class='text-muted'>" + dcuser.presence.status + "</small></div>"

        }

    }
    out = discordTag
    p.identifiers.forEach(ident => {
        let service = ident.split(":")[0];
        service = service.replace(/^./, service[0].toUpperCase()); // First letter uppercase
        out = out + boldin + service + ": " + boldout + ident
    })
}

function hasDiscord(idents) {
    idents.forEach(ident => {
        if(ident.startsWith("discord:"))
            return true
    })
    return false;
}