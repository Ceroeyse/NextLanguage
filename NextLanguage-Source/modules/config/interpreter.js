const path = require('node:path');

module.exports = function readConfig(source, directory) {
    const config = { main: undefined, others: [], plugins: [] };
    for (const [index, text] of source.split('\n').entries()) {
        const line = text.trim();
        if (!line || line.startsWith('#')) continue;
        const entry = line.match(/^PACKAGES:\s+@(main|others)\s+(.+)$/);
        if (entry) {
            const [, kind, filename] = entry;
            const resolved = path.resolve(directory, filename);
            if (kind === 'main') config.main = resolved;
            else config.others.push(resolved);
            continue;
        }
        const builtIn = line.match(/^PLUGINS:\s+(Secure|Debugger)\s+@require\(.*\);?\s+@sign\s+null$/);
        if (builtIn) {
            const service = builtIn[1] === 'Secure'
                ? require('../../package/bulit-in/Secure/package')
                : require('../../package/bulit-in/Debugger/package').DebugService;
            config.plugins.push(service);
            continue;
        }
        const external = line.match(/^PLUGINS:\s+(\S+)\s+@path:\s*(.+?)\s+@sign\s+(.+)$/);
        if (external) {
            const [, name, filename, metadata] = external;
            config.plugins.push(() => require('../../package/bulit-in/Secure/default')(
                path.resolve(directory, filename), name, path.resolve(directory, metadata)
            ));
            continue;
        }
        throw new SyntaxError(`package.config.val line ${index + 1}: Unrecognized setting`);
    }
    return config;
};
