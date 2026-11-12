const path = require('path');

const run = require('../../start.js');
const addOutput = require('../../../build/lib/output/addOutput.js');

const Packages = require('../../../modules/class/Packages.js');
const Debug = require('../../../modules/class/Debug.js');

const debug = new Debug;
const package = new Packages;

function DebugService() {
    // Registers the plugin
    const Debugger = package.create('package', path.join(__dirname, 'default.js'), 'Debugger');
    Debugger.config('package', 'Debugger', 'enabled', true);

    // Package Information
    Debugger.config('package', 'Debugger', 'author', 'RBLAuthorizations');
    Debugger.config('package', 'Debugger', 'version', '0.1.0');
    Debugger.config('package', 'Debugger', 'repo', 'https://github.com/nxoscloud/Debugger/');
    Debugger.config('package', 'Debugger', 'description', '(Debugging package for NextLanguage) A package which debugs other parts of nextlanguage. This package is to be allowed full access to NextLanguages Modules.');
}

async function startDebug(file, value) {
    /**
     * @param {string} file - The path to the debug file
     * @param {boolean} value
     * @description Start the debugging process for NextLanguage
     * @example
     * startDebug('./function/outputVariables.debug', true);
     */
    if (value) debug.setValue(value);
    const active = debug.debugMode

    if (active === true) {
        addOutput('Debugging is enabled');
        await run(path.join(__dirname, file));
    } else {
        addOutput('Debugging is disabled');
    }
}

module.exports = { DebugService, startDebug };