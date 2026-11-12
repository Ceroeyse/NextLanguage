const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'nextlanguage-build-'));
const cli = path.join(__dirname, 'cli.js');
const execute = (...args) => execFileSync(process.execPath, [cli, ...args], { cwd: directory, encoding: 'utf8' });

try {
    const source = path.join('my project', 'main.nxl');
    const buildOutput = execute('build', source);
    assert.match(buildOutput, /Oh no! Sam died/);
    assert.equal(fs.readFileSync(path.join(directory, 'main.config.file'), 'utf8').trim(), source);
    assert.equal(execute('run'), buildOutput);
    fs.writeFileSync(path.join(directory, source), '@output Existing source\n');
    assert.equal(execute('build'), 'Existing source\n');
    fs.writeFileSync(path.join(directory, 'main.config.file'), '');
    fs.writeFileSync(path.join(directory, 'package.config.val'), `PACKAGES: @main ${source}\n`);
    assert.equal(execute('build'), 'Existing source\n');
    assert.equal(fs.readFileSync(path.join(directory, 'main.config.file'), 'utf8').trim(), source);
    console.log('Project build and restart passed.');
} finally {
    fs.rmSync(directory, { force: true, recursive: true });
}
