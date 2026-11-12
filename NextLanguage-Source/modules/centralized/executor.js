const path = require('node:path');
const { createInterface } = require('node:readline');
const addOutput = require('../../build/lib/output/addOutput');
const evaluateCondition = require('./evaluater');
const { readArguments, readValue, unquote } = evaluateCondition;
const loadAST = require('./loader');

module.exports = async function centralExecutor(ast, file = path.resolve('app.nxl')) {
    const modules = new Map();
    let input;
    let reader;

    try {
        return await runModule(ast, path.resolve(file), new Set());
    } finally {
        input?.close();
    }

    async function runModule(nodes, filename, ancestors) {
        const context = {
            variables: Object.create(null),
            functions: Object.create(null),
            exports: Object.create(null),
            filename,
            ancestors: new Set([...ancestors, filename]),
        };
        await execute(nodes, context);
        return context.exports;
    }

    async function execute(nodes, context) {
        const { variables, functions } = context;
        for (const node of nodes) {
            switch (node.type) {
                case 'Variable':
                    variables[node.name] = parseValue(node.value, node.param);
                    break;
                case 'SetVariable': {
                    if (!Object.hasOwn(variables, node.name)) throw new Error(`Undefined variable: ${node.name}`);
                    const previous = variables[node.name];
                    const value = readValue(node.value, variables);
                    variables[node.name] = parseValue(value, previous.param);
                    break;
                }
                case 'OutputStatement': {
                    const variable = variables[node.value];
                    addOutput(variable ? variable.display ?? variable.value : unquote(node.value));
                    break;
                }
                case 'IfStatement':
                    await execute(evaluateCondition(node.condition, variables) ? node.consequent : node.alternate, context);
                    break;
                case 'Function':
                    functions[node.name] = { node, context };
                    break;
                case 'Call': {
                    const fn = functions[node.param];
                    if (!fn) throw new Error(`Undefined function: ${node.param}`);
                    const parameters = fn.node.body[0]?.type === 'Parameters' ? fn.node.body[0].names : [];
                    const args = readArguments(node.args, variables);
                    if (args.length !== parameters.length) {
                        throw new Error(`Function ${node.param} expects ${parameters.length} argument(s)`);
                    }
                    const locals = Object.assign(Object.create(null), fn.context.variables);
                    parameters.forEach((name, index) => { locals[name] = { value: args[index] }; });
                    await execute(fn.node.body.slice(parameters.length ? 1 : 0), {
                        ...fn.context,
                        variables: locals,
                        functions: Object.assign(Object.create(null), fn.context.functions),
                    });
                    break;
                }
                case 'WhileLoop':
                    while (evaluateCondition(node.condition, variables)) await execute(node.body, context);
                    break;
                case 'ForLoop': {
                    const match = node.range.match(/^(-?\d+)\s*\.\.\s*(-?\d+)(?:\s+step\s+(\d+))?$/);
                    if (!match) throw new Error(`Invalid range: ${node.range}`);
                    const [, start, end, step = '1'] = match;
                    const bounds = [Number(start), Number(end), Number(step)];
                    if (!bounds.every(Number.isSafeInteger) || bounds[2] < 1) {
                        throw new Error(`Invalid range: ${node.range}`);
                    }
                    for (let i = bounds[0]; i <= bounds[1]; i += bounds[2]) {
                        variables[node.variable] = { value: i, param: 'integer' };
                        await execute(node.body, context);
                    }
                    break;
                }
                case 'InputStatement': {
                    if (!input) {
                        input = createInterface({ input: process.stdin, terminal: false, crlfDelay: Infinity });
                        reader = input[Symbol.asyncIterator]();
                    }
                    process.stdout.write(`${node.prompt}: `);
                    const next = await reader.next();
                    if (next.done) throw new Error(`End of input while reading ${node.variable}`);
                    variables[node.variable] = { value: next.value };
                    break;
                }
                case 'ImportPackage': {
                    const filename = path.resolve(path.dirname(context.filename), unquote(node.value));
                    if (context.ancestors.has(filename)) throw new Error(`Circular import: ${filename}`);
                    if (!modules.has(filename)) {
                        modules.set(filename, await runModule(loadAST(filename), filename, context.ancestors));
                    }
                    if (node.name !== 'null') {
                        const fn = modules.get(filename)[node.name];
                        if (!fn) throw new Error(`Package ${filename} does not export ${node.name}`);
                        functions[node.name] = fn;
                    }
                    break;
                }
                case 'ExportPackage':
                    if (!functions[node.value]) throw new Error(`Undefined export: ${node.value}`);
                    context.exports[node.value] = functions[node.value];
                    break;
                case 'Packaged':
                    await execute(node.body, context);
                    break;
                case 'PackageDirective':
                    break;
                case 'Parameters':
                    throw new Error(':params must be the first statement in a function');
                default:
                    throw new Error(`Error processing node: ${node.type}`);
            }
        }
    }
};

function parseValue(raw, param) {
    let value = raw;
    let display;
    switch (param) {
        case undefined:
        case 'string':
            value = typeof raw === 'string' ? unquote(raw) : String(raw);
            break;
        case 'boolean':
            if (!['true', 'false', true, false].includes(raw)) throw new Error(`Invalid boolean: ${raw}`);
            value = raw === true || raw === 'true';
            break;
        case 'int':
        case 'integer':
        case 'negative':
        case 'negatives':
            value = Number(raw);
            if (raw === '' || !Number.isSafeInteger(value)) throw new Error(`Invalid integer: ${raw}`);
            break;
        case 'double':
            value = Number(raw);
            if (raw === '' || !Number.isFinite(value)) throw new Error(`Invalid number: ${raw}`);
            break;
        case 'percentage':
        case 'percent':
            if (typeof raw === 'string' && raw.endsWith('%')) {
                display = raw;
                value = Number(raw.slice(0, -1)) / 100;
            } else {
                value = Number(raw);
            }
            if (raw === '' || !Number.isFinite(value)) throw new Error(`Invalid percentage: ${raw}`);
            break;
        default:
            throw new Error(`Unknown variable type: ${param}`);
    }
    return { value, param, display };
}
