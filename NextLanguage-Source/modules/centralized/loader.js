const { readFileSync } = require('node:fs');
const centralParse = require('./parser');

module.exports = function loadAST(filePath) {
    try {
        return centralParse(readFileSync(filePath, 'utf8').split('\n'));
    } catch (error) {
        throw new Error(`Failed to load AST from ${filePath}: ${error.message}`, { cause: error });
    }
};
