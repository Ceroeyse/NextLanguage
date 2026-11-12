const centralParse = require('../../../../../modules/centralized/parser');

describe('centralParse', () => {
    it('parses valid lines into AST nodes', () => {
        const lines = [
            '@var [x]: (integer)10',
            '@function [testFunction]:',
            '@output Hello, World!',
            '@end',
        ];
        const ast = centralParse(lines);
        expect(ast).toEqual([
            { type: 'Variable', name: 'x', param: 'integer', value: '10' },
            {
                type: 'Function', name: 'testFunction', body: [
                    { type: 'OutputStatement', value: 'Hello, World!', line: '@output Hello, World!' },
                ],
            },
        ]);
    });

    it('reports unknown commands and unmatched blocks with a source line', () => {
        expect(() => centralParse(['# comment', '@else'])).toThrow('Line 2: Unexpected @else');
        expect(() => centralParse(['@if [true]:'])).toThrow('Line 1: Unclosed IfStatement');
        expect(() => centralParse(['@outpt text'])).toThrow('Line 1: Unknown or malformed command');
    });

    it('ignores comments and empty lines', () => {
        const lines = [
            '# This is a comment',
            '',
            '@output Hello!',
        ];
        const ast = centralParse(lines);
        expect(ast).toEqual([
            { type: 'OutputStatement', value: 'Hello!', line: '@output Hello!' },
        ]);
    });
});
