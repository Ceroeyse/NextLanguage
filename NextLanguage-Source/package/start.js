const path = require('node:path');
const execute = require('../modules/centralized/executor');
const loadAST = require('../modules/centralized/loader');

module.exports = async function run(file) {
    const filename = path.resolve(file);
    return execute(loadAST(filename), filename);
};
