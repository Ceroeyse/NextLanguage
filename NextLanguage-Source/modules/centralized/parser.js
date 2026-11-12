const name = '[a-zA-Z0-9_]+';
const variable = new RegExp(`^@var(?:iable)?\\s+\\[(${name})\\]:\\s*(?:\\((\\w+)\\)\\s*)?(.*)$`);
const definition = new RegExp(`^@function\\s+\\[(${name})\\]\\s*:$`);
const call = new RegExp(`^(?:@call\\s+:function|@run\\s*)\\[(${name})\\](?:\\s*\\((.*)\\))?$`);

module.exports = function centralParse(lines) {
    const ast = [];
    const blocks = [{ body: ast }];

    for (const [index, source] of lines.entries()) {
        const line = source.trim().replace(/;$/, '').trimEnd();
        if (!line || line.startsWith('#')) continue;

        const block = blocks.at(-1);
        const fail = message => { throw new SyntaxError(`Line ${index + 1}: ${message}`); };
        if (line === '@else' || line === '@else:') {
            if (block.node?.type !== 'IfStatement' || block.body === block.node.alternate) {
                fail('Unexpected @else');
            }
            block.body = block.node.alternate;
            continue;
        }
        if (line === '@end' || line === ']' || line === ':end') {
            // Older programs use :end after individual commands inside a block.
            if (line === ':end') continue;
            if (blocks.length === 1 || (line === ']') !== (block.node.type === 'Packaged')) {
                fail(`Unexpected ${line}`);
            }
            blocks.pop();
            continue;
        }

        const node = parseLine(line);
        if (!node) fail(`Unknown or malformed command: ${line}`);
        block.body.push(node);
        const body = node.consequent ?? node.body;
        if (body) blocks.push({ node, body, line: index + 1 });
    }

    if (blocks.length > 1) {
        const block = blocks.at(-1);
        throw new SyntaxError(`Line ${block.line}: Unclosed ${block.node.type}`);
    }
    return ast;
};

function parseLine(line) {
    let match;
    if ((match = line.match(variable))) {
        return { type: 'Variable', name: match[1], param: match[2], value: match[3] };
    }
    if ((match = line.match(/^[@:]output\s+(.+)$/))) {
        return { type: 'OutputStatement', value: match[1], line };
    }
    if ((match = line.match(definition))) {
        return { type: 'Function', name: match[1], body: [] };
    }
    if ((match = line.match(call))) {
        return { type: 'Call', param: match[1], args: match[2] };
    }
    if ((match = line.match(/^:params\s+(.+)$/))) {
        const names = match[1].replace(/^\[|\]$/g, '').split(/\s*,\s*/);
        if (new Set(names).size === names.length && names.every(value => /^[a-zA-Z_]\w*$/.test(value))) {
            return { type: 'Parameters', names };
        }
        return;
    }
    if ((match = line.match(/^@if\s+\[(.+)\]\s*:?$/))) {
        return { type: 'IfStatement', condition: match[1], consequent: [], alternate: [] };
    }
    if ((match = line.match(/^@while\s+\[(.+)\]\s*:$/))) {
        return { type: 'WhileLoop', condition: match[1], body: [] };
    }
    if ((match = line.match(/^@for\s+\[(\w+)\]\s+\w+\s+\[(.+)\]\s*:$/))) {
        return { type: 'ForLoop', variable: match[1], range: match[2], body: [] };
    }
    if ((match = line.match(/^@input\s+\[(.+)\]:\s*(\w+)$/))) {
        return { type: 'InputStatement', prompt: match[1], variable: match[2] };
    }
    if ((match = line.match(/^:set\s+\[@variable\]:\s*\/(\w+)\((.*)\)$/))) {
        return { type: 'SetVariable', name: match[1], value: match[2] };
    }
    if ((match = line.match(/^:packages\s+(\w+|null)\s+@import\s+(.+)$/))) {
        return { type: 'ImportPackage', name: match[1], value: match[2] };
    }
    if ((match = line.match(/^:packages\s+(\w+)\s+@export$/))) {
        return { type: 'ExportPackage', value: match[1] };
    }
    if (line === ':packaged [') return { type: 'Packaged', body: [] };
    if (/^:package-(?:main\s+\S+|com\s+x-auto|advanced\s+(?:true|false))$/.test(line)) {
        return { type: 'PackageDirective' };
    }
}
