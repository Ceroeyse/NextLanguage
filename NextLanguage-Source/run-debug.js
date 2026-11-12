const { startDebug } = require('./package/bulit-in/Debugger/package');

async function main() {
    for (const file of ['outputVariables', 'ifCommand', 'functionState']) {
        await startDebug(`./normal-tests/${file}.debug`, true);
    }
}

main().catch(error => {
    console.error(error.message);
    process.exitCode = 1;
});
