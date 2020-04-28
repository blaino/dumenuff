// TODO pass in the user name so Rivescript can tailor


require('./node_modules/babel-polyfill')
const RiveScript = require('./node_modules/rivescript/lib/rivescript.js');

const bot = new RiveScript();

module.exports = async function(message) {
    let output = ''
    async function loading_done() {
        bot.sortReplies();

        // RiveScript remembers user data by their username and can tell
        // multiple users apart.
        let username = "local-user";

        // NOTE: the API has changed in v2.0.0 and returns a Promise now.
        let promise = bot.reply(username, message).then((reply) => {
            return reply
        });

        let result = await promise

        output = result
        return result
    }

    const loading_error = (error, filename, lineno) => {
        return "Error when loading files: " + error;
    }

    await bot.loadFile(__dirname + "/eliza.rive").then(loading_done).catch(loading_error);
    return output
}
