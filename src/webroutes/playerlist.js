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
    let playerHtml = rowstart + card.replace("{{HEADER}}", "Hey").replace("{{BODY}}", players.join()) + rowend;

    let renderData = {
        headerTitle: 'Playerlist',
        players: playerHtml
    }

    let out = await webUtils.renderMasterView('playerlist', req.session, renderData);
    return res.send(out);
};
