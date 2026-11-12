const fs = require('node:fs');
const path = require('node:path');

const logDirectory = path.join(__dirname, '../../log');

module.exports = function addOutput(text) {
    console.log(text);
    fs.mkdirSync(logDirectory, { recursive: true });
    const date = new Date().toISOString().slice(0, 10);
    fs.appendFileSync(path.join(logDirectory, `${date}-NXL.log`), `${text}\n`, 'utf8');
};
