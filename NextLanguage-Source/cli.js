const fs = require('node:fs');
const path = require('node:path');
const readConfig = require('./modules/config/interpreter');
const packageTemplate = require('./modules/config/template');
const { returns } = require('./patches/v1.8/returns');
const run = require('./package/start');

function readOptional(filename) {
    try {
        return fs.readFileSync(filename, 'utf8');
    } catch (error) {
        if (error.code !== 'ENOENT') throw error;
        return '';
    }
}

function createFile(filename, content) {
    try {
        fs.writeFileSync(filename, content, { encoding: 'utf8', flag: 'wx' });
    } catch (error) {
        if (error.code !== 'EEXIST') throw error;
    }
}

async function project(mode, filename, directory = process.cwd()) {
    const mainConfig = path.join(directory, 'main.config.file');
    const packageConfig = path.join(directory, 'package.config.val');
    const configuredPath = readOptional(mainConfig).trim();
    const config = readConfig(readOptional(packageConfig), directory);
    const entry = filename || configuredPath || config.main || (mode === 'build' && 'app.nxl');
    if (!entry) throw new Error('No main file configured. Run the build command or pass a file path.');
    const main = path.resolve(directory, entry);

    if (mode === 'build') {
        fs.mkdirSync(path.dirname(main), { recursive: true });
        createFile(main, returns().template.indexFile + '\n');
        createFile(packageConfig, packageTemplate);
        const relative = path.relative(directory, main) || path.basename(main);
        fs.writeFileSync(mainConfig, relative + '\n', 'utf8');
    }

    for (const plugin of config.plugins) await plugin();
    for (const file of new Set([main, ...config.others])) await run(file);
}

function main(mode, args = process.argv.slice(2)) {
    const usage = 'Usage: nextlanguage [run|build] [file.nxl]';
    if (args[0] === '--help' || args[0] === '-h') {
        console.log(usage);
        return;
    }
    if (args.length > 1 || args[0]?.startsWith('-')) {
        console.error(usage);
        process.exitCode = 1;
        return;
    }
    return project(mode, args[0]).catch(error => {
        console.error(error.message);
        process.exitCode = 1;
    });
}

if (require.main === module) {
    const args = process.argv.slice(2);
    const command = ['build', 'run'].includes(args[0]) ? args.shift() : 'run';
    main(command, args);
}

module.exports = { main };
