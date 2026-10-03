const fs = require('node:fs');
const path = require('node:path');

const root = path.join(__dirname, '..');
const isCheck = process.argv.includes('--check');

function normalizeNewlines(str) {
  return str.replace(/\r\n/g, '\n');
}

// 1. Build Standalone HTML
const indexHtml = normalizeNewlines(fs.readFileSync(path.join(root, 'dist', 'index.html'), 'utf8'));
const css = normalizeNewlines(fs.readFileSync(path.join(root, 'dist', 'style.css'), 'utf8')).replace(/^@import[^\n]*\n/, '');
const engine = normalizeNewlines(fs.readFileSync(path.join(root, 'dist', 'engine.js'), 'utf8'));
const renderer = normalizeNewlines(fs.readFileSync(path.join(root, 'dist', 'renderer.js'), 'utf8'));
const game = normalizeNewlines(fs.readFileSync(path.join(root, 'dist', 'game.js'), 'utf8'));

const singleHtml = indexHtml
  .replace('  <link rel="stylesheet" href="style.css">', '  <style>' + css + '</style>')
  .replace('  <script defer src="engine.js"></script><script defer src="renderer.js"></script><script defer src="game.js"></script>', '')
  .replace('</body>\n</html>', '<script>' + engine + '\n' + renderer + '\n' + game + '</script>\n</body>\n</html>');

// 2. Build SOURCE_CODE.txt
const sourceFiles = [
  'README.md',
  '.openai/hosting.json',
  'dist/engine.js',
  'dist/game.js',
  'dist/index.html',
  'dist/renderer.js',
  'dist/style.css'
];

const testsDir = path.join(root, 'tests');
const testFiles = fs.readdirSync(testsDir)
  .filter(f => f.endsWith('.cjs'))
  .sort()
  .map(f => 'tests/' + f);

const allFiles = [...sourceFiles, ...testFiles];

let sourceTxt = '';
for (let i = 0; i < allFiles.length; i++) {
  const f = allFiles[i];
  const content = normalizeNewlines(fs.readFileSync(path.join(root, f), 'utf8'));
  sourceTxt += '\n===== ' + f + ' =====\n' + content + (i < allFiles.length - 1 ? '\n' : '');
}

const singleHtmlPath = path.join(root, 'Zerava-zlievaren.html');
const sourceTxtPath = path.join(root, 'SOURCE_CODE.txt');

if (isCheck) {
  let ok = true;
  if (fs.existsSync(singleHtmlPath)) {
    const existingHtml = normalizeNewlines(fs.readFileSync(singleHtmlPath, 'utf8'));
    if (existingHtml !== singleHtml) {
      console.error('ERROR: Zerava-zlievaren.html is out of sync with dist/. Run `npm run bundle` to regenerate.');
      ok = false;
    }
  } else {
    console.error('ERROR: Zerava-zlievaren.html does not exist.');
    ok = false;
  }

  if (fs.existsSync(sourceTxtPath)) {
    const existingTxt = normalizeNewlines(fs.readFileSync(sourceTxtPath, 'utf8'));
    if (existingTxt !== sourceTxt) {
      console.error('ERROR: SOURCE_CODE.txt is out of sync. Run `npm run bundle` to regenerate.');
      ok = false;
    }
  } else {
    console.error('ERROR: SOURCE_CODE.txt does not exist.');
    ok = false;
  }

  if (!ok) {
    process.exit(1);
  }
  console.log('OK: Zerava-zlievaren.html and SOURCE_CODE.txt are up to date.');
} else {
  fs.writeFileSync(singleHtmlPath, singleHtml, 'utf8');
  fs.writeFileSync(sourceTxtPath, sourceTxt, 'utf8');
  console.log('Successfully bundled Zerava-zlievaren.html and SOURCE_CODE.txt.');
}
