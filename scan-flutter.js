const fs = require('fs');
const path = require('path');

const projectRoot = process.cwd();
const desktopPath = path.join(process.env.USERPROFILE, 'Desktop', 'Flutter-Project-Map.md');

let md = `# 📱 Flutter Proje Haritası\n\n`;
md += `**Oluşturulma:** ${new Date().toLocaleString('tr-TR')}\n`;
md += `**Proje Klasörü:** \`${projectRoot}\`\n\n`;

// pubspec.yaml'ı oku
try {
  const pubspec = fs.readFileSync('pubspec.yaml', 'utf-8');
  const nameMatch = pubspec.match(/^name:\s*(.+)$/m);
  const versionMatch = pubspec.match(/^version:\s*(.+)$/m);
  
  md += `## 📋 Proje Bilgileri\n`;
  if (nameMatch) md += `- **Ad:** ${nameMatch[1]}\n`;
  if (versionMatch) md += `- **Versiyon:** ${versionMatch[1]}\n`;
  md += '\n';
} catch (e) {}

// lib/ yapısı
md += `## 📁 Dosya Yapısı (lib/)\n\n\`\`\`\n`;

function scanDir(dir, prefix = '') {
  try {
    const files = fs.readdirSync(dir).sort();
    files.forEach((file, index) => {
      const filePath = path.join(dir, file);
      const stat = fs.statSync(filePath);
      const isLast = index === files.length - 1;
      const connector = isLast ? '└── ' : '├── ';
      const nextPrefix = isLast ? '    ' : '│   ';

      if (stat.isDirectory() && !file.startsWith('.')) {
        md += `${prefix}${connector}📁 ${file}/\n`;
        scanDir(filePath, prefix + nextPrefix);
      } else if (file.endsWith('.dart')) {
        md += `${prefix}${connector}📄 ${file}\n`;
      }
    });
  } catch (e) {}
}

scanDir('lib');
md += `\`\`\`\n\n`;

fs.writeFileSync(desktopPath, md, 'utf-8');
console.log(`✅ Dosya kaydedildi: ${desktopPath}`);