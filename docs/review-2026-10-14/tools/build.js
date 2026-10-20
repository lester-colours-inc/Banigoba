// Builds ../README.md and ../Banigoba_Review_Checklist.docx from
// checklist.json, so the two never drift. Usage: npm install && npm run build
const fs = require('fs');
const path = require('path');
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow,
  TableCell, WidthType, ShadingType, BorderStyle, AlignmentType, LevelFormat,
} = require('docx');

const data = JSON.parse(fs.readFileSync(path.join(__dirname, 'checklist.json'), 'utf8'));
const outDir = path.join(__dirname, '..');

const ids = data.tiers.flatMap((t) => t.items.map((i) => i.id));
const dupes = ids.filter((id, i) => ids.indexOf(id) !== i);
if (dupes.length) throw new Error(`Duplicate ids: ${dupes}`);

const slug = (s) => s.toLowerCase().replace(/[^a-z0-9 -]/g, '').trim().replace(/\s+/g, '-');
const isPrinciples = (t) => t.name.startsWith('Principles');
const findingDone = (f) => f.status.startsWith('Fixed') && !/needs deploy/i.test(f.status);

// ---------- Markdown ----------
const md = [`# ${data.title}`, ''];
md.push(`**Meeting:** ${data.meeting}  `, `**Prepared by:** ${data.preparedBy}  `,
  `**Status:** ${data.status}  `, `**Target:** ${data.target}`, '');
md.push('Tick items off as they ship. Item IDs (e.g. `H-2`) match the Word version (`Banigoba_Review_Checklist.docx`).', '');
md.push('Items are ordered easiest and clearest first. The ID prefix shows the app area (H = Home, M = Makeover, W = Wardrobe, …).', '');
md.push('_Generated from `tools/checklist.json`; edit that file and run `npm run build` in `tools/`._', '');
md.push('## Contents', '');
data.tiers.forEach((t) => {
  const done = t.items.filter((i) => i.done).length;
  md.push(`- [${t.name}](#${slug(t.name)})${isPrinciples(t) ? '' : ` — ${done}/${t.items.length} done`}`);
});
md.push('- [Issues found while working](#issues-found-while-working)', '- [Open questions](#open-questions)', '');
data.tiers.forEach((t) => {
  md.push(`## ${t.name}`, '', `_${t.blurb}_`, '');
  t.items.forEach((i) => {
    md.push(`- [${i.done ? 'x' : ' '}] **${i.id}** ${i.text} — ${i.area}${i.note ? ` _(${i.note})_` : ''}`);
    if (i.progress) md.push(`  - **Progress:** ${i.progress}`);
  });
  md.push('');
});
md.push('## Issues found while working', '', '_Not raised in the meeting; found while building._', '');
data.findings.forEach((f) => {
  md.push(`- [${findingDone(f) ? 'x' : ' '}] **${f.id}** ${f.text} _(${f.status})_`);
  md.push(`  - **Action:** ${f.action}`);
});
md.push('', '## Open questions', '');
data.openQuestions.forEach((q, i) => md.push(`${i + 1}. ${q}`));
md.push('');
fs.writeFileSync(path.join(outDir, 'README.md'), md.join('\n'));

// ---------- DOCX ----------
const NAVY = '1F2A44';
const PAGE_W = 11906 - 2 * 1134; // A4 minus 2 cm margins
const COLS = [720, 760, 5120, PAGE_W - 6600];
const border = { style: BorderStyle.SINGLE, size: 4, color: 'C9CED8' };
const borders = { top: border, bottom: border, left: border, right: border };

const cell = (text, width, opts = {}) => new TableCell({
  width: { size: width, type: WidthType.DXA },
  borders,
  margins: { top: 60, bottom: 60, left: 100, right: 100 },
  shading: opts.fill ? { type: ShadingType.CLEAR, color: 'auto', fill: opts.fill } : undefined,
  children: [new Paragraph({
    alignment: opts.center ? AlignmentType.CENTER : AlignmentType.LEFT,
    children: [new TextRun({ text, bold: !!opts.bold, italics: !!opts.italics, color: opts.color, size: opts.size || 20 })],
  })],
});
const headerRow = (labels) => new TableRow({
  tableHeader: true,
  children: labels.map((h, i) => cell(h, COLS[i], { bold: true, fill: NAVY, color: 'FFFFFF', center: i < 2 })),
});
const table = (labels, rows) => new Table({
  width: { size: PAGE_W, type: WidthType.DXA }, columnWidths: COLS, rows: [headerRow(labels), ...rows],
});
const row = (done, id, text, notes) => new TableRow({ children: [
  cell(done ? '☑' : '☐', COLS[0], { center: true, size: 24 }),
  cell(id, COLS[1], { center: true, bold: true }),
  cell(text, COLS[2]),
  cell(notes, COLS[3], { italics: true, color: '5A6273', size: 18 }),
] });
const h1 = (text) => new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun(text)] });
const blurb = (text) => new Paragraph({ spacing: { after: 100 }, children: [new TextRun({ text, italics: true, color: '5A6273' })] });

const children = [
  new Paragraph({ heading: HeadingLevel.TITLE, children: [new TextRun(data.title)] }),
  ...[['Meeting', data.meeting], ['Prepared by', data.preparedBy], ['Status', data.status], ['Target', data.target]]
    .map(([k, v]) => new Paragraph({ children: [new TextRun({ text: `${k}: `, bold: true }), new TextRun(v)] })),
  new Paragraph({
    spacing: { before: 120, after: 120 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: NAVY, space: 4 } },
    children: [new TextRun({ text: 'Ordered easiest and clearest first. Tick items off as they ship. IDs match the README in the repo.', italics: true })],
  }),
];
data.tiers.forEach((t) => {
  children.push(h1(t.name), blurb(t.blurb), table(['Done', 'ID', 'Item', 'Area · Notes'], t.items.map((i) =>
    row(i.done, i.id, i.text, [i.area, i.note, i.progress && `Progress: ${i.progress}`].filter(Boolean).join(' · ')))));
});
children.push(h1('Issues found while working'), blurb('Not raised in the meeting; found while building.'),
  table(['Done', 'ID', 'Issue', 'Status · Action'], data.findings.map((f) => row(findingDone(f), f.id, f.text, `${f.status} · ${f.action}`))));
children.push(h1('Open questions'));
data.openQuestions.forEach((q) => children.push(new Paragraph({ numbering: { reference: 'q', level: 0 }, children: [new TextRun(q)] })));

const doc = new Document({
  styles: {
    default: { document: { run: { font: 'Calibri', size: 21 } } },
    paragraphStyles: [
      { id: 'Title', name: 'Title', basedOn: 'Normal', run: { size: 40, bold: true, color: NAVY }, paragraph: { spacing: { after: 160 } } },
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 26, bold: true, color: NAVY }, paragraph: { spacing: { before: 320, after: 120 }, outlineLevel: 0 } },
    ],
  },
  numbering: { config: [{ reference: 'q', levels: [{ level: 0, format: LevelFormat.DECIMAL, text: '%1.', alignment: AlignmentType.LEFT,
    style: { paragraph: { indent: { left: 500, hanging: 300 }, spacing: { after: 80 } } } }] }] },
  sections: [{ properties: { page: { size: { width: 11906, height: 16838 }, margin: { top: 1134, bottom: 1134, left: 1134, right: 1134 } } }, children }],
});
Packer.toBuffer(doc).then((buf) => {
  fs.writeFileSync(path.join(outDir, 'Banigoba_Review_Checklist.docx'), buf);
  console.log('Built README.md and Banigoba_Review_Checklist.docx');
});
