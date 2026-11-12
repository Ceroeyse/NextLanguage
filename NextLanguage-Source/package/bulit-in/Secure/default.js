const Packages = require('../../../modules/class/Packages');
const Local = require('../../../build/lib/memoryStore/Local');
const addOutput = require('../../../build/lib/output/addOutput');
const debugOutput = require('../../../build/lib/output/debugOutput');

module.exports = async function loadPlugin(filename, name, metadata) {
    const info = require(metadata)();
    if (info.name !== name) throw new Error(`Plugin metadata name does not match ${name}`);
    if (!info.enabled) return;

    const service = require(filename);
    if (typeof service !== 'function') throw new TypeError(`Plugin ${name} must export a function`);
    await service({ package: new Packages(), local: new Local(), addOutput, debugOutput });
};
