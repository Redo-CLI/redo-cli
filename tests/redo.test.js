const { execSync } = require('child_process');

test('Prints help message, version and configuration', async () => {
    const data =  execSync('./redo.sh').toString();
    expect(data.indexOf("Redo helps you do more without leaving the terminal.")).toBe(0);
});

test('Tests clean command', async () => {
    const data =  execSync('./redo.sh clean').toString();
    console.log(data);
    expect(data).toContain("All local commands were cleared");
});


test('Test hello-world command', async () => {
    const data =  execSync('./redo.sh hello-world').toString();
    expect(data).toContain("Redo command not found on local:");
    expect(data).toContain("Download public command: hello-world");
    expect(data).toContain("Hello World!");
});

// test('Test hello-world command', async () => {
//     const data =  execSync('./redo.sh hello-world').toString();
//     expect(data).toContain("Hello World!");
// });