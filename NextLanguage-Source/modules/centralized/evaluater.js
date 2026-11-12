const operators = [
    { '||': (a, b) => a() || b() },
    { '&&': (a, b) => a() && b() },
    { '===': (a, b) => a() === b(), '!==': (a, b) => a() !== b(),
        '==': (a, b) => a() == b(), '!=': (a, b) => a() != b() },
    { '<': (a, b) => a() < b(), '<=': (a, b) => a() <= b(),
        '>': (a, b) => a() > b(), '>=': (a, b) => a() >= b() },
    { '+': (a, b) => a() + b(), '-': (a, b) => a() - b() },
    { '*': (a, b) => a() * b(), '/': (a, b) => a() / b(), '%': (a, b) => a() % b() },
];

const tokenPattern = /\s+|"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?(?:%(?!\s*[\w.'"(]))?|[a-zA-Z_][a-zA-Z0-9_]*|===|!==|==|!=|<=|>=|&&|\|\||[!<>+*/%(),-]|./gs;
const unary = { '!': value => !value, '+': value => +value, '-': value => -value };

function unquote(text) {
    if (text.startsWith('"') && text.endsWith('"')) return JSON.parse(text);
    if (text.startsWith("'") && text.endsWith("'")) {
        return text.slice(1, -1).replace(/\\(['\\nrt])/g, (_, char) => (
            { n: '\n', r: '\r', t: '\t' }[char] ?? char
        ));
    }
    return text;
}

function readExpressions(source, variables, multiple = false) {
    const tokens = (source.match(tokenPattern) ?? []).filter(token => token.trim());
    let index = 0;

    function operand() {
        const token = tokens[index++];
        if (Object.hasOwn(unary, token)) {
            const value = operand();
            return () => unary[token](value());
        }
        if (token === '(') {
            const value = expression(0);
            if (tokens[index++] !== ')') throw new SyntaxError('Expected closing parenthesis');
            return value;
        }
        if (/^["']/.test(token ?? '') && token.length > 1) return () => unquote(token);
        if (/^(?:\d|\.\d)/.test(token ?? '')) {
            return () => token.endsWith('%') ? Number(token.slice(0, -1)) / 100 : Number(token);
        }
        if (token === 'true' || token === 'false') return () => token === 'true';
        if (token === 'null') return () => null;
        if (/^[a-zA-Z_]\w*$/.test(token ?? '')) {
            return () => {
                if (!Object.hasOwn(variables, token)) throw new Error(`Undefined variable: ${token}`);
                return variables[token].value;
            };
        }
        throw new SyntaxError(`Unexpected token: ${token ?? 'end of expression'}`);
    }

    function expression(level) {
        if (level === operators.length) return operand();
        const group = operators[level];
        let left = expression(level + 1);
        while (Object.hasOwn(group, tokens[index])) {
            const apply = group[tokens[index++]];
            const previous = left;
            const right = expression(level + 1);
            left = () => apply(previous, right);
        }
        return left;
    }

    const values = [expression(0)];
    while (multiple && tokens[index] === ',') {
        index++;
        values.push(expression(0));
    }
    if (index < tokens.length) throw new SyntaxError(`Unexpected token: ${tokens[index]}`);
    return values.map(value => value());
}

function evaluateCondition(condition, variables) {
    try {
        return Boolean(readExpressions(condition, variables)[0]);
    } catch (error) {
        console.error(`Error evaluating condition "${condition}": ${error.message}`);
        return false;
    }
}

module.exports = evaluateCondition;
module.exports.readArguments = (source, variables) => source?.trim()
    ? readExpressions(source, variables, true)
    : [];
module.exports.readValue = (source, variables) => readExpressions(source, variables)[0];
module.exports.unquote = unquote;
