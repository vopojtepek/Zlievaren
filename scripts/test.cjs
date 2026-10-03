const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const testsDir = path.join(__dirname, '..', 'tests');
const files = fs.readdirSync(testsDir)
  .filter(f => f.endsWith('.cjs') && f !== 'fixtures.cjs')
  .sort();

console.log(`Running ${files.length} test suites...\n`);

let passedCount = 0;
let failedCount = 0;

for (const file of files) {
  const filePath = path.join(testsDir, file);
  console.log(`=== ${file} ===`);
  const result = spawnSync(process.execPath, [filePath], { stdio: 'inherit' });
  if (result.status === 0) {
    passedCount++;
  } else {
    failedCount++;
    console.error(`FAILED: ${file} exited with code ${result.status}`);
  }
}

console.log('\n=======================================');
console.log(`Test Summary: ${passedCount} passed, ${failedCount} failed out of ${files.length} suites.`);
if (failedCount > 0) {
  process.exit(1);
}
