const { execSync } = require('child_process');
const fs = require('fs');
const homedir = require('os').homedir();

test('Prints help message, version and configuration', async () => {
    const data =  execSync('./redo.sh').toString();
    expect(data).toContain("Redo helps you do more without leaving the terminal.");
});

test('Tests clean command', async () => {
    const data =  execSync('./redo.sh clean').toString();
    expect(data).toContain("All local commands were cleared");
    expect(fs.existsSync(homedir+"/.redo/commands/hello-world.sh")).toBe(false)
});


test('Test 1.hello-world command', async () => {
    const data =  execSync('./redo.sh hello-world').toString();
    expect(data).toContain("Redo command not found on local:");
    expect(data).toContain("Download public command: hello-world");
    expect(data).toContain("Hello World!");
});

test('Test 2.edit command', async () => {
    const data =  execSync('./redo.sh edit test').toString();
    expect(data).toContain("Edit");
    expect(data).toContain("/private_commands/test.sh");
});


test('Test 3.search command', async () => {
    const data =  execSync('./redo.sh search hello').toString();
    expect(data).toContain("redo hello-world")
});

test('Test 4.publish command', async () => {
    const data =  execSync('./redo.sh publish test').toString();
    expect(data).toContain("test v0.0.1 already exists, bumpt the version and retry.");
});

test('Test 5.update command', async () => {
    const data =  execSync('./redo.sh update').toString();
    expect(data).toContain("Download public command: hello-world")
    expect(fs.existsSync(homedir+"/.redo/commands/hello-world.sh")).toBe(true)
});
