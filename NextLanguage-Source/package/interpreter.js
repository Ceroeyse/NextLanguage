const centralParse = require('../modules/centralized/parser');
const execute = require('../modules/centralized/executor');

module.exports = async function compiler(lines, file) {
    return execute(centralParse(lines), file);
};
