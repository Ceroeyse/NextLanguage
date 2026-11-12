const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const centralExecutor = require('../../../../../modules/centralized/executor');
const parse = require('../../../../../modules/centralized/parser');
const addOutput = require('../../../../../build/lib/output/addOutput');

jest.mock('../../../../../build/lib/output/addOutput');

const run = (source, filename) => centralExecutor(parse(source.split('\n')), filename);
const output = () => addOutput.mock.calls.map(([value]) => value);

beforeEach(() => addOutput.mockClear());

it('executes nested branches and repeated function calls in source order', async () => {
    await run(`
        @var [name]: "Someone";
        @function [hello]:
            :params [show]
            @if [show === true && name === "Someone"]:
                :output name
                :end
                @output first
            @else
                @output alternate
            @end
        @end
        @output before
        @call :function[hello](true)
        @call :function[hello](false)
        @call :function[hello](true)
        @output after
    `);
    expect(output()).toEqual(['before', 'Someone', 'first', 'alternate', 'Someone', 'first', 'after']);
});

it('executes while and for loops with normal variable and output semantics', async () => {
    await run(`
        @var [x]: (integer)2
        @while [x > 0]:
            @output x
            :set [@variable]: /x(x - 1)
        @end
        @for [i] in [1..3 step 2]:
            @output each
            @output i
        @end
        @output done
    `);
    expect(output()).toEqual([2, 1, 'each', 1, 'each', 3, 'done']);
});

it('resolves imports from the importing file and runs each module once per invocation', async () => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'nxl-import-'));
    try {
        const filename = path.join(dir, 'lib.nxl');
        fs.writeFileSync(filename, `
            @output loaded
            @var [private]: module value
            @function [greet]:
                @output private
            @end
            :packages greet @export
        `);
        const main = path.join(dir, 'main.nxl');
        const source = ':packages null @import lib.nxl\n:packages greet @import lib.nxl\n@call :function[greet]';
        await run(source, main);
        expect(output()).toEqual(['loaded', 'module value']);
        addOutput.mockClear();
        fs.writeFileSync(filename, fs.readFileSync(filename, 'utf8').replace('module value', 'updated'));
        await run(source, main);
        expect(output()).toEqual(['loaded', 'updated']);
    } finally {
        fs.rmSync(dir, { recursive: true, force: true });
    }
});

it('reports undefined calls and invalid loop steps', async () => {
    await expect(run('@call :function[missing]')).rejects.toThrow('Undefined function: missing');
    await expect(run('@for [i] in [0..2 step 0]:\n@end')).rejects.toThrow('Invalid range');
});
