const { execSync, exec } = require('child_process');
const fs = require('fs');
const homedir = require('os').homedir();
const demoToken = "4|O4LOvd6uOBh8hRW7EDw89z0IleKB6AgfYE9wq3XN";

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
    const data =  execSync('./redo.sh edit test-command').toString();
    expect(data).toContain("Edit");
    expect(data).toContain("/private_commands/test-command.sh");
});


test('Test 3.search command', async () => {
    const data =  execSync('./redo.sh search hello').toString();
    expect(data).toContain("redo hello-world")
});

test('Test 4.publish command', async () => {
    const data =  execSync('./redo.sh publish test-command').toString();
    expect(data).toContain("test-command v0.0.1 already exists, bumpt the version and retry.");
});

test('Test 5.update command', async () => {
    const data =  execSync('./redo.sh update').toString();
    expect(data).toContain("Download public command: hello-world")
    expect(fs.existsSync(homedir+"/.redo/commands/hello-world.sh")).toBe(true)
});

test('Test login command', async () => {
    //This access token is useless, this account is only for demo purpose.
    const data =  execSync('echo "'+demoToken+'" | ./redo.sh login').toString();
    expect(data).toContain("Login succeeded!");
});

test('Test push command', async () => {
    const data =  execSync('./redo.sh push test-command').toString();
    expect(data).toContain("test-command v0.0.1 already exists, bumpt the version and retry");
});

test('Test pull command', async () => {
    const data =  execSync('./redo.sh pull test-command').toString();
    expect(data).toContain("Not pulled, use --force to replace with current local version");
});

test('Test pull command with --force', async () => {
    const data =  execSync('./redo.sh pull test-command --force').toString();
    expect(data).toContain("Updated command file: test-command")
    expect(fs.existsSync(homedir+"/.redo/private_commands/test-command.sh")).toBe(true)
});

test('Test configure command', async () => {
    let data =  execSync('./redo.sh configure').toString();
    expect(data).toContain("redo configure <key> <value>")

    //Test with key value
    data =  execSync('./redo.sh configure api-token testtoken').toString();
    expect(data).toContain("API Token updated!")

    data =  execSync("cat '"+homedir+"/.redo/config/api-token'").toString()
    expect(data).toContain("testtoken")

    execSync('echo "'+demoToken+'" | ./redo.sh login').toString();
    data =  execSync("cat '"+homedir+"/.redo/config/api-token'").toString()
    expect(data).toContain(demoToken)

});

//Clean command tested at the top, skip

test('Test list command', async () => {
    let data =  execSync('./redo.sh  list').toString();
    expect(data).toContain("Available commands on your local disk:");
});

test('Test upgrade command', async () => {
    let data =  execSync('./redo.sh  upgrade').toString();
    expect(data).toContain("Installation complete.");
    expect(fs.existsSync("/usr/local/bin/redo")).toBe(true)
});

test('Test help command', async () => {
    const data =  execSync('./redo.sh -h').toString();
    expect(data).toContain("Redo helps you do more without leaving the terminal.");
});

test('Test version command', async () => {
    const data =  execSync('./redo.sh -v').toString();
    expect(data).toContain("Redo CLI v");
});
