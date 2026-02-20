#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const repoRoot = process.cwd();
const githubBlobBase = 'https://github.com/jpetrucciani/hex/blob/main';
const helmRoot = path.join(repoRoot, 'hex', 'hex', 'k8s', 'helm');
const svcRoot = path.join(repoRoot, 'hex', 'hex', 'k8s', 'svc');
const servicesFile = path.join(repoRoot, 'hex', 'hex', 'k8s', 'services.nix');
const docsRefDir = path.join(repoRoot, 'docs', 'reference');
const chartsDir = path.join(docsRefDir, 'charts');
const svcDir = path.join(docsRefDir, 'svc');
const helpersDir = path.join(docsRefDir, 'helpers');
const metaFile = path.join(docsRefDir, 'meta.json');

const toPosix = (p) => p.split(path.sep).join('/');
const relRepo = (p) => toPosix(path.relative(repoRoot, p));

const helperSpecs = [
  {
    moduleName: 'cron',
    moduleAttrPath: 'hex.k8s.cron',
    sourceFile: path.join(repoRoot, 'hex', 'hex', 'k8s', 'cron.nix'),
    functions: [
      { name: 'build', scopeChain: ['cron = {'], marker: 'build =' },
      { name: 'kube_cron.build', scopeChain: ['cron = {', 'kube_cron = {'], marker: 'build =' },
    ],
  },
  {
    moduleName: 'storage',
    moduleAttrPath: 'hex.k8s.storage',
    sourceFile: path.join(repoRoot, 'hex', 'hex', 'k8s', 'storage.nix'),
    functions: [
      { name: 'nfs_pv', scopeChain: null, marker: 'nfs_pv =' },
      { name: 'local_pv', scopeChain: null, marker: 'local_pv =' },
    ],
  },
  {
    moduleName: 'tailscale',
    moduleAttrPath: 'hex.k8s.tailscale',
    sourceFile: path.join(repoRoot, 'hex', 'hex', 'k8s', 'tailscale.nix'),
    functions: [
      { name: 'sa', scopeChain: ['proxies = rec {'], marker: 'sa =' },
      { name: 'secret', scopeChain: ['proxies = rec {'], marker: 'secret =' },
      { name: 'role', scopeChain: ['proxies = rec {'], marker: 'role =' },
      { name: 'role-binding', scopeChain: ['proxies = rec {'], marker: 'role-binding =' },
      { name: 'network-policy', scopeChain: ['proxies = rec {'], marker: 'network-policy =' },
      { name: 'proxy.build', scopeChain: ['proxies = rec {', 'proxy = rec {'], marker: 'build =' },
      { name: 'cloudsql-proxy.build', scopeChain: ['proxies = rec {', 'cloudsql-proxy = rec {'], marker: 'build =' },
    ],
  },
];

const chartHelperTopLevelIgnore = new Set([
  'chart',
  'chart_url',
  'defaults',
  'docs_meta',
  'index_url',
  'name',
  'values_url',
  'version',
]);

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function exists(p) {
  return fs.existsSync(p);
}

function walkFiles(root, predicate) {
  const out = [];
  const stack = [root];
  while (stack.length > 0) {
    const current = stack.pop();
    const entries = fs.readdirSync(current, { withFileTypes: true });
    for (const entry of entries) {
      const abs = path.join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(abs);
        continue;
      }
      if (predicate(abs, entry.name)) {
        out.push(abs);
      }
    }
  }
  return out.sort((a, b) => a.localeCompare(b));
}

function loadJson(filePath, fallback) {
  if (!exists(filePath)) {
    return fallback;
  }
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function writeFile(filePath, text) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, text, 'utf8');
}

function resetGeneratedDir(dirPath) {
  ensureDir(dirPath);
  for (const entry of fs.readdirSync(dirPath, { withFileTypes: true })) {
    fs.rmSync(path.join(dirPath, entry.name), { recursive: true, force: true });
  }
}

function ensureMetaFile() {
  if (exists(metaFile)) {
    return;
  }
  const seed = {
    charts: {},
    svc: {},
    helpers: {},
  };
  writeFile(metaFile, `${JSON.stringify(seed, null, 2)}\n`);
}

function slugFromAttr(attrPath, prefix = 'hex.k8s.') {
  const core = attrPath.startsWith(prefix) ? attrPath.slice(prefix.length) : attrPath;
  return core.replaceAll('.', '-');
}

function findBraceEnd(source, startIndex) {
  let depth = 0;
  let inDouble = false;
  let inMultiSingle = false;
  let inLineComment = false;

  for (let i = startIndex; i < source.length; i += 1) {
    const ch = source[i];
    const next = source[i + 1] || '';
    const prev = source[i - 1] || '';

    if (inLineComment) {
      if (ch === '\n') {
        inLineComment = false;
      }
      continue;
    }

    if (inDouble) {
      if (ch === '"' && prev !== '\\') {
        inDouble = false;
      }
      continue;
    }

    if (inMultiSingle) {
      if (ch === "'" && next === "'") {
        inMultiSingle = false;
        i += 1;
      }
      continue;
    }

    if (ch === '#') {
      inLineComment = true;
      continue;
    }

    if (ch === '"' && !inDouble) {
      inDouble = true;
      continue;
    }

    if (ch === "'" && next === "'") {
      inMultiSingle = true;
      i += 1;
      continue;
    }

    if (ch === '{') {
      depth += 1;
      continue;
    }

    if (ch === '}') {
      depth -= 1;
      if (depth === 0) {
        return i;
      }
    }
  }

  return -1;
}

function splitTopLevelByDelimiter(block, delimiter) {
  const parts = [];
  let current = '';
  let curly = 0;
  let square = 0;
  let paren = 0;
  let letDepth = 0;
  let inDouble = false;
  let inMultiSingle = false;
  let inLineComment = false;

  for (let i = 0; i < block.length; i += 1) {
    const ch = block[i];
    const next = block[i + 1] || '';
    const prev = block[i - 1] || '';

    if (inLineComment) {
      current += ch;
      if (ch === '\n') {
        inLineComment = false;
      }
      continue;
    }

    if (inDouble) {
      current += ch;
      if (ch === '"' && prev !== '\\') {
        inDouble = false;
      }
      continue;
    }

    if (inMultiSingle) {
      current += ch;
      if (ch === "'" && next === "'") {
        current += next;
        inMultiSingle = false;
        i += 1;
      }
      continue;
    }

    if (ch === '#') {
      inLineComment = true;
      current += ch;
      continue;
    }

    if (ch === '"') {
      inDouble = true;
      current += ch;
      continue;
    }

    if (ch === "'" && next === "'") {
      inMultiSingle = true;
      current += ch;
      current += next;
      i += 1;
      continue;
    }

    if (ch === '{') {
      curly += 1;
      current += ch;
      continue;
    }
    if (ch === '}') {
      curly = Math.max(0, curly - 1);
      current += ch;
      continue;
    }
    if (ch === '[') {
      square += 1;
      current += ch;
      continue;
    }
    if (ch === ']') {
      square = Math.max(0, square - 1);
      current += ch;
      continue;
    }
    if (ch === '(') {
      paren += 1;
      current += ch;
      continue;
    }
    if (ch === ')') {
      paren = Math.max(0, paren - 1);
      current += ch;
      continue;
    }

    if (delimiter === ';' && curly === 0 && square === 0 && paren === 0) {
      const isIdent = (value) => /[A-Za-z0-9_.+-]/.test(value || '');
      if (ch === 'l' && block.slice(i, i + 3) === 'let') {
        const before = block[i - 1] || '';
        const after = block[i + 3] || '';
        if (!isIdent(before) && !isIdent(after)) {
          letDepth += 1;
        }
      } else if (ch === 'i' && next === 'n') {
        const before = block[i - 1] || '';
        const after = block[i + 2] || '';
        if (!isIdent(before) && !isIdent(after)) {
          letDepth = Math.max(0, letDepth - 1);
        }
      }
    }

    if (ch === delimiter && curly === 0 && square === 0 && paren === 0 && letDepth === 0) {
      parts.push(current);
      current = '';
      continue;
    }

    current += ch;
  }

  if (current.trim() !== '') {
    parts.push(current);
  }

  return parts;
}

function splitTopLevelArgs(block) {
  return splitTopLevelByDelimiter(block, ',');
}

function splitTopLevelStatements(block) {
  return splitTopLevelByDelimiter(block, ';');
}

function isWrappedByMatchingParens(value) {
  let depth = 0;
  let inDouble = false;
  let inMultiSingle = false;
  let inLineComment = false;

  for (let i = 0; i < value.length; i += 1) {
    const ch = value[i];
    const next = value[i + 1] || '';
    const prev = value[i - 1] || '';

    if (inLineComment) {
      if (ch === '\n') {
        inLineComment = false;
      }
      continue;
    }

    if (inDouble) {
      if (ch === '"' && prev !== '\\') {
        inDouble = false;
      }
      continue;
    }

    if (inMultiSingle) {
      if (ch === "'" && next === "'") {
        inMultiSingle = false;
        i += 1;
      }
      continue;
    }

    if (ch === '#') {
      inLineComment = true;
      continue;
    }

    if (ch === '"') {
      inDouble = true;
      continue;
    }

    if (ch === "'" && next === "'") {
      inMultiSingle = true;
      i += 1;
      continue;
    }

    if (ch === '(') {
      depth += 1;
      continue;
    }

    if (ch === ')') {
      depth -= 1;
      if (depth === 0 && i < value.length - 1) {
        return false;
      }
    }
  }

  return depth === 0;
}

function stripOuterParens(value) {
  let out = value.trim();
  while (out.startsWith('(') && out.endsWith(')') && isWrappedByMatchingParens(out)) {
    out = out.slice(1, -1).trim();
  }
  return out;
}

function inferArgType(defaultValue) {
  if (defaultValue === null) {
    return 'unknown';
  }

  const normalized = stripOuterParens(String(defaultValue).trim());
  if (!normalized) {
    return 'unknown';
  }

  if (normalized === 'true' || normalized === 'false') {
    return 'bool';
  }
  if (normalized === 'null') {
    return 'null';
  }
  if (/^-?\d+(?:\.\d+)?$/.test(normalized)) {
    return 'number';
  }
  if (
    (normalized.startsWith('"') && normalized.endsWith('"')) ||
    (normalized.startsWith("''") && normalized.endsWith("''"))
  ) {
    return 'string';
  }
  if (normalized.startsWith('[') && normalized.endsWith(']')) {
    return 'list';
  }
  if (normalized.startsWith('{') && normalized.endsWith('}')) {
    return 'attrset';
  }

  const ifMatch = normalized.match(/^if\s+[\s\S]+?\s+then\s+([\s\S]+?)\s+else\s+([\s\S]+)$/);
  if (ifMatch) {
    const thenType = inferArgType(ifMatch[1].trim());
    const elseType = inferArgType(ifMatch[2].trim());
    if (thenType === elseType) {
      return thenType;
    }
    if (thenType === 'unknown') {
      return elseType;
    }
    if (elseType === 'unknown') {
      return thenType;
    }
    return `${thenType} | ${elseType}`;
  }

  return 'unknown';
}

function parseDocsNotesFromCommentLines(lines) {
  const notes = [];
  for (const line of lines || []) {
    const trimmed = line.trim();
    if (!trimmed.startsWith('#')) {
      continue;
    }

    const body = trimmed.replace(/^#\s*/, '').trim();
    const match = body.match(/^(?:docs?|description)\s*:\s*(.+)$/i);
    if (!match) {
      continue;
    }

    const note = match[1].trim();
    if (note) {
      notes.push(note);
    }
  }
  return notes;
}

function parseArgTypeHint(note) {
  if (!note) {
    return { typeHint: null, cleanNote: '' };
  }

  const match = note.match(/\btype\s*:\s*([^;]+)(?:;|$)/i);
  if (!match) {
    return { typeHint: null, cleanNote: note };
  }

  const typeHint = match[1].replace(/\s+/g, ' ').trim() || null;
  const withoutType = `${note.slice(0, match.index)}${note.slice(match.index + match[0].length)}`
    .replace(/\s+/g, ' ')
    .trim()
    .replace(/^[-:,;]\s*/, '')
    .replace(/\s*[-:,;]$/, '');

  return {
    typeHint,
    cleanNote: withoutType,
  };
}

function parseArgsFromBlock(block) {
  const segments = splitTopLevelArgs(block);
  const args = [];

  for (const segment of segments) {
    const raw = segment.trim();
    if (!raw) {
      continue;
    }

    const noteParts = [];
    const codeLines = [];
    for (const line of raw.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed) {
        continue;
      }

      if (trimmed.startsWith('#')) {
        noteParts.push(trimmed.replace(/^#\s*/, '').trim());
        continue;
      }

      const inlineCommentMatch = line.match(/^(.*?)(?:\s+#\s*(.+))?$/);
      const code = inlineCommentMatch?.[1] ?? line;
      const inlineNote = inlineCommentMatch?.[2]?.trim() ?? '';
      if (inlineNote) {
        noteParts.push(inlineNote);
      }
      if (code.trim()) {
        codeLines.push(code);
      }
    }

    const note = noteParts.join(' ').replace(/\s+/g, ' ').trim();
    const withoutComments = codeLines.join('\n').trim();
    if (!withoutComments) {
      continue;
    }

    const match = withoutComments.match(/^([A-Za-z0-9_.+-]+)(?:\s*\?\s*([\s\S]+))?$/);
    if (!match) {
      continue;
    }

    const name = match[1];
    const defaultValue = match[2] ? match[2].replace(/\s+/g, ' ').trim() : null;
    const inferredType = inferArgType(defaultValue);
    const typeAndNote = parseArgTypeHint(note);
    args.push({
      name,
      required: defaultValue === null,
      defaultValue,
      note: typeAndNote.cleanNote,
      type: typeAndNote.typeHint || inferredType,
    });
  }

  return args;
}

function collectFunctionArgBlocks(source) {
  const out = [];
  for (let i = 0; i < source.length; i += 1) {
    if (source[i] !== '{') {
      continue;
    }
    const end = findBraceEnd(source, i);
    if (end < 0) {
      continue;
    }
    let j = end + 1;
    while (j < source.length && /\s/.test(source[j])) {
      j += 1;
    }
    if (source[j] !== ':') {
      i = end;
      continue;
    }
    out.push({ start: i, end, block: source.slice(i + 1, end) });
    i = end;
  }
  return out;
}

function findScopeRangeByMarker(source, marker, range) {
  const scopeStart = source.indexOf(marker, range.start);
  if (scopeStart < 0 || scopeStart >= range.end) {
    return null;
  }
  const braceStart = source.indexOf('{', scopeStart);
  if (braceStart < 0 || braceStart >= range.end) {
    return null;
  }
  const braceEnd = findBraceEnd(source, braceStart);
  if (braceEnd < 0 || braceEnd > range.end) {
    return null;
  }
  return { start: braceStart + 1, end: braceEnd };
}

function resolveScopeRange(source, scopeChain) {
  let range = { start: 0, end: source.length };
  for (const marker of scopeChain || []) {
    const nextRange = findScopeRangeByMarker(source, marker, range);
    if (!nextRange) {
      return null;
    }
    range = nextRange;
  }
  return range;
}

function extractFunctionArgsByMarker(source, marker, range) {
  const idx = source.indexOf(marker, range.start);
  if (idx < 0 || idx >= range.end) {
    return null;
  }
  const braceStart = source.indexOf('{', idx);
  if (braceStart < 0 || braceStart >= range.end) {
    return null;
  }
  const braceEnd = findBraceEnd(source, braceStart);
  if (braceEnd < 0 || braceEnd >= range.end) {
    return null;
  }

  let colonIdx = braceEnd + 1;
  while (colonIdx < source.length && /\s/.test(source[colonIdx])) {
    colonIdx += 1;
  }
  if (source[colonIdx] !== ':') {
    return null;
  }

  return parseArgsFromBlock(source.slice(braceStart + 1, braceEnd));
}

function parseTopLevelBindingsFromAttrset(block) {
  const bindings = [];
  for (const statement of splitTopLevelStatements(block)) {
    const rawLines = statement.split(/\r?\n/);
    let offset = 0;
    while (offset < rawLines.length && rawLines[offset].trim() === '') {
      offset += 1;
    }

    const leadingCommentLines = [];
    while (offset < rawLines.length && rawLines[offset].trim().startsWith('#')) {
      leadingCommentLines.push(rawLines[offset]);
      offset += 1;
    }

    const lines = rawLines.slice(offset).filter((line) => line.trim() !== '');
    if (lines.length === 0) {
      continue;
    }

    const trimmed = lines.join('\n').trim();
    if (!trimmed) {
      continue;
    }
    const match = trimmed.match(/^([A-Za-z0-9_.+-]+)\s*=\s*([\s\S]+)$/);
    if (!match) {
      continue;
    }
    bindings.push({
      key: match[1],
      value: match[2].trim(),
      notes: parseDocsNotesFromCommentLines(leadingCommentLines),
    });
  }
  return bindings;
}

function parseDocsNotesBeforeIndex(source, index) {
  if (!Number.isInteger(index) || index < 0) {
    return [];
  }

  const lines = source.slice(0, index).split(/\r?\n/);
  let cursor = lines.length - 1;
  while (cursor >= 0 && lines[cursor].trim() === '') {
    cursor -= 1;
  }

  const commentLines = [];
  while (cursor >= 0) {
    const line = lines[cursor];
    if (!line.trim().startsWith('#')) {
      break;
    }
    commentLines.push(line);
    cursor -= 1;
  }

  return parseDocsNotesFromCommentLines(commentLines.reverse());
}

function isIdentChar(ch) {
  return /[A-Za-z0-9_.+-]/.test(ch || '');
}

function escapeRegExp(value) {
  return String(value || '').replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function unwrapLeadingLetIn(value) {
  const trimmed = stripOuterParens(value.trim());
  if (!trimmed.startsWith('let')) {
    return trimmed;
  }

  let curly = 0;
  let square = 0;
  let paren = 0;
  let inDouble = false;
  let inMultiSingle = false;
  let inLineComment = false;

  for (let i = 3; i < trimmed.length; i += 1) {
    const ch = trimmed[i];
    const next = trimmed[i + 1] || '';
    const prev = trimmed[i - 1] || '';

    if (inLineComment) {
      if (ch === '\n') {
        inLineComment = false;
      }
      continue;
    }

    if (inDouble) {
      if (ch === '"' && prev !== '\\') {
        inDouble = false;
      }
      continue;
    }

    if (inMultiSingle) {
      if (ch === "'" && next === "'") {
        inMultiSingle = false;
        i += 1;
      }
      continue;
    }

    if (ch === '#') {
      inLineComment = true;
      continue;
    }

    if (ch === '"') {
      inDouble = true;
      continue;
    }

    if (ch === "'" && next === "'") {
      inMultiSingle = true;
      i += 1;
      continue;
    }

    if (ch === '{') {
      curly += 1;
      continue;
    }
    if (ch === '}') {
      curly = Math.max(0, curly - 1);
      continue;
    }
    if (ch === '[') {
      square += 1;
      continue;
    }
    if (ch === ']') {
      square = Math.max(0, square - 1);
      continue;
    }
    if (ch === '(') {
      paren += 1;
      continue;
    }
    if (ch === ')') {
      paren = Math.max(0, paren - 1);
      continue;
    }

    if (curly === 0 && square === 0 && paren === 0 && ch === 'i' && next === 'n') {
      const before = trimmed[i - 1] || '';
      const after = trimmed[i + 2] || '';
      if (!isIdentChar(before) && !isIdentChar(after)) {
        return trimmed.slice(i + 2).trim();
      }
    }
  }

  return trimmed;
}

function findForwardedCallInLambdaBody(body, paramName) {
  const escapedParam = escapeRegExp(paramName);
  const callRegex = new RegExp(`\\b([A-Za-z0-9_.+-]+)\\s+\\(?\\s*${escapedParam}\\b`, 'g');
  const candidates = [];
  for (const match of body.matchAll(callRegex)) {
    const candidate = match[1];
    if (!candidate || candidate === paramName) {
      continue;
    }
    candidates.push(candidate);
  }
  return candidates[0] || null;
}

function isYamlWrapperLambda(body, forwardedCall) {
  if (!forwardedCall || !body) {
    return false;
  }

  if (!/\btoYAMLDoc\b/.test(body)) {
    return false;
  }

  const forwardedRegex = new RegExp(`\\b${escapeRegExp(forwardedCall)}\\b`);
  return forwardedRegex.test(body);
}

function parseLeadingAttrsetValue(value) {
  const trimmed = unwrapLeadingLetIn(value);
  const recPrefixMatch = trimmed.match(/^rec\s+/);
  const offset = recPrefixMatch ? recPrefixMatch[0].length : 0;
  if (trimmed[offset] !== '{') {
    return null;
  }

  const braceStart = offset;
  const braceEnd = findBraceEnd(trimmed, braceStart);
  if (braceEnd < 0) {
    return null;
  }

  let suffixIdx = braceEnd + 1;
  while (suffixIdx < trimmed.length && /\s/.test(trimmed[suffixIdx])) {
    suffixIdx += 1;
  }

  return {
    block: trimmed.slice(braceStart + 1, braceEnd),
    isLambda: trimmed[suffixIdx] === ':',
  };
}

function parseFunctionArgsFromValue(value) {
  const normalized = unwrapLeadingLetIn(value);
  const attrsetValue = parseLeadingAttrsetValue(normalized);
  if (attrsetValue?.isLambda) {
    return {
      args: parseArgsFromBlock(attrsetValue.block),
      forwardedCall: null,
    };
  }

  const simpleLambdaMatch = normalized.match(/^([A-Za-z0-9_.+-]+)\s*:\s*([\s\S]+)$/);
  if (!simpleLambdaMatch) {
    return null;
  }

  const paramName = simpleLambdaMatch[1];
  const body = simpleLambdaMatch[2].trim();
  const forwardedCall = findForwardedCallInLambdaBody(body, paramName);
  return {
    args: [
      {
        name: paramName,
        required: true,
        defaultValue: null,
        note: '',
        type: 'unknown',
      },
    ],
    forwardedCall,
    yamlWrapper: isYamlWrapperLambda(body, forwardedCall),
  };
}

function extractFunctionsFromAttrsetBlock(block, pathSegments = []) {
  const out = [];
  for (const binding of parseTopLevelBindingsFromAttrset(block)) {
    const nextPath = [...pathSegments, binding.key];
    const parsedFn = parseFunctionArgsFromValue(binding.value);
    if (parsedFn) {
      out.push({
        name: nextPath.join('.'),
        pathSegments: nextPath,
        args: parsedFn.args,
        forwardedCall: parsedFn.forwardedCall,
        forwardedTarget: null,
        yamlWrapper: parsedFn.yamlWrapper === true,
        notes: binding.notes || [],
      });
      continue;
    }

    const nestedAttrset = parseLeadingAttrsetValue(binding.value);
    if (nestedAttrset && !nestedAttrset.isLambda) {
      out.push(...extractFunctionsFromAttrsetBlock(nestedAttrset.block, nextPath));
    }
  }
  return out;
}

function resolveForwardedFunctionName(currentName, forwardedCall, knownNames) {
  if (!forwardedCall || !knownNames.has(currentName)) {
    return null;
  }

  const currentSegments = currentName.split('.');
  const forwardedSegments = String(forwardedCall).split('.');
  for (let depth = currentSegments.length - 1; depth >= 0; depth -= 1) {
    const candidate = [...currentSegments.slice(0, depth), ...forwardedSegments].join('.');
    if (knownNames.has(candidate)) {
      return candidate;
    }
  }

  return knownNames.has(forwardedCall) ? forwardedCall : null;
}

function resolveForwardedHelperArgs(functions) {
  const byName = new Map(functions.map((fn) => [fn.name, fn]));
  const knownNames = new Set(byName.keys());
  const cache = new Map();
  const resolving = new Set();

  const resolveArgs = (name) => {
    const fn = byName.get(name);
    if (!fn) {
      return [];
    }
    if (cache.has(name)) {
      return cache.get(name);
    }
    if (resolving.has(name)) {
      return fn.args.map((arg) => ({ ...arg }));
    }

    resolving.add(name);
    let resolved = fn.args;
    if (fn.forwardedCall) {
      const targetName = resolveForwardedFunctionName(name, fn.forwardedCall, knownNames);
      if (targetName && targetName !== name) {
        const targetArgs = resolveArgs(targetName);
        if (targetArgs.length > 0) {
          resolved = targetArgs;
        }
      }
    }
    resolving.delete(name);

    const cloned = resolved.map((arg) => ({ ...arg }));
    cache.set(name, cloned);
    return cloned;
  };

  for (const fn of functions) {
    fn.forwardedTarget = fn.forwardedCall ? resolveForwardedFunctionName(fn.name, fn.forwardedCall, knownNames) : null;
    fn.args = resolveArgs(fn.name).map((arg) => ({ ...arg }));
  }
}

function attachForwardedWrapperNotes(functions) {
  for (const fn of functions) {
    if (!fn.yamlWrapper || !fn.forwardedTarget) {
      continue;
    }

    const note = `returns YAML as a string; \`${fn.forwardedTarget}\` returns an attrset.`;
    const existing = Array.isArray(fn.notes) ? fn.notes : [];
    if (!existing.includes(note)) {
      fn.notes = [...existing, note];
    }
  }
}

function isAssignedAttrsetRange(source, range) {
  let prefixEnd = range.start - 1;
  while (prefixEnd >= 0 && /\s/.test(source[prefixEnd])) {
    prefixEnd -= 1;
  }

  const prefix = source.slice(Math.max(0, prefixEnd - 200), prefixEnd + 1);
  if (!/=\s*(?:rec\s*)?$/.test(prefix)) {
    return false;
  }

  let suffixStart = range.end + 1;
  while (suffixStart < source.length && /\s/.test(source[suffixStart])) {
    suffixStart += 1;
  }
  return source[suffixStart] !== ':';
}

function findEnclosingAssignedAttrsetRange(source, markerIndex) {
  const candidates = [];
  for (let i = 0; i < source.length; i += 1) {
    if (source[i] !== '{') {
      continue;
    }
    const end = findBraceEnd(source, i);
    if (end < 0) {
      continue;
    }
    if (i <= markerIndex && markerIndex <= end && isAssignedAttrsetRange(source, { start: i, end })) {
      candidates.push({ start: i, end });
    }
  }

  if (candidates.length === 0) {
    return null;
  }

  candidates.sort((a, b) => (a.end - a.start) - (b.end - b.start));
  return candidates[0];
}

function chartAttrsetBlockByVersionFile(source, versionFileName) {
  const marker = `versionFile = ./${versionFileName}`;
  const markerIndex = source.indexOf(marker);
  if (markerIndex < 0) {
    return null;
  }

  const scopeRange = findEnclosingAssignedAttrsetRange(source, markerIndex);
  if (!scopeRange) {
    return null;
  }

  return source.slice(scopeRange.start + 1, scopeRange.end);
}

function shouldIncludeChartHelperFunction(pathSegments) {
  if (!Array.isArray(pathSegments) || pathSegments.length === 0) {
    return false;
  }
  return !chartHelperTopLevelIgnore.has(pathSegments[0]);
}

function extractChartHelperFunctions(source, attrPath, versionFileName) {
  const chartBlock = chartAttrsetBlockByVersionFile(source, versionFileName);
  if (!chartBlock) {
    return [];
  }

  const allFunctions = extractFunctionsFromAttrsetBlock(chartBlock).filter((fn) =>
    shouldIncludeChartHelperFunction(fn.pathSegments),
  );
  resolveForwardedHelperArgs(allFunctions);
  attachForwardedWrapperNotes(allFunctions);

  const unique = [];
  const seen = new Set();
  for (const fn of allFunctions) {
    if (seen.has(fn.name)) {
      continue;
    }
    seen.add(fn.name);
    unique.push({
      name: fn.name,
      attrPath: `${attrPath}.${fn.name}`,
      args: fn.args,
      notes: fn.notes || [],
    });
  }

  unique.sort((a, b) => a.attrPath.localeCompare(b.attrPath));
  return unique;
}

function findChartModuleSource(jsonFilePath) {
  const dir = path.dirname(jsonFilePath);
  const defaultFile = path.join(dir, 'default.nix');
  if (exists(defaultFile)) {
    return defaultFile;
  }

  const dirName = path.basename(dir);
  const siblingNix = path.join(helmRoot, `${dirName}.nix`);
  if (exists(siblingNix)) {
    return siblingNix;
  }

  return null;
}

function valuesUrlFromDir(dirPath) {
  const nixFiles = fs
    .readdirSync(dirPath, { withFileTypes: true })
    .filter((d) => d.isFile() && d.name.endsWith('.nix'))
    .map((d) => path.join(dirPath, d.name));

  const urls = new Set();
  for (const file of nixFiles) {
    const text = fs.readFileSync(file, 'utf8');
    const regex = /values_url\s*=\s*"([^"]+)"/g;
    for (const match of text.matchAll(regex)) {
      urls.add(match[1]);
    }
  }

  return [...urls][0] || null;
}

function toVersionAttr(version) {
  const raw = String(version || '').trim();
  if (!raw) {
    return 'latest';
  }
  const withoutLeadingV = raw.replace(/^v/i, '');
  return `v${withoutLeadingV.replaceAll('.', '-')}`;
}

function parseDateMs(dateLike) {
  if (!dateLike) {
    return Number.NaN;
  }
  const ms = Date.parse(dateLike);
  return Number.isFinite(ms) ? ms : Number.NaN;
}

function versionTokens(version) {
  return String(version || '')
    .replace(/^v/i, '')
    .toLowerCase()
    .split(/[.-]/)
    .filter((token) => token.length > 0);
}

function compareVersionTextDesc(a, b) {
  const aTokens = versionTokens(a);
  const bTokens = versionTokens(b);
  const maxLen = Math.max(aTokens.length, bTokens.length);

  for (let i = 0; i < maxLen; i += 1) {
    const aToken = aTokens[i];
    const bToken = bTokens[i];
    if (aToken === undefined && bToken === undefined) {
      return 0;
    }
    if (aToken === undefined) {
      return 1;
    }
    if (bToken === undefined) {
      return -1;
    }

    const aNum = Number(aToken);
    const bNum = Number(bToken);
    const aIsNum = Number.isFinite(aNum);
    const bIsNum = Number.isFinite(bNum);

    if (aIsNum && bIsNum) {
      if (aNum !== bNum) {
        return aNum > bNum ? 1 : -1;
      }
      continue;
    }

    if (aIsNum && !bIsNum) {
      return 1;
    }
    if (!aIsNum && bIsNum) {
      return -1;
    }

    const cmp = aToken.localeCompare(bToken);
    if (cmp !== 0) {
      return cmp > 0 ? 1 : -1;
    }
  }

  return 0;
}

function compareVersionEntriesDesc(a, b) {
  const aDate = parseDateMs(a.date);
  const bDate = parseDateMs(b.date);
  const aHasDate = Number.isFinite(aDate);
  const bHasDate = Number.isFinite(bDate);

  if (aHasDate && bHasDate && aDate !== bDate) {
    return bDate - aDate;
  }
  if (aHasDate && !bHasDate) {
    return -1;
  }
  if (!aHasDate && bHasDate) {
    return 1;
  }

  return -compareVersionTextDesc(a.version, b.version);
}

function shortDate(dateLike) {
  const ms = parseDateMs(dateLike);
  if (!Number.isFinite(ms)) {
    return null;
  }
  return new Date(ms).toISOString().slice(0, 10);
}

function placeholderForRequiredArg(arg, moduleName) {
  const argName = arg.name;
  const typeTokens = String(arg.type || '')
    .toLowerCase()
    .split('|')
    .map((token) => token.trim())
    .filter(Boolean);

  if (argName === 'name') {
    return `"${moduleName}"`;
  }
  if (argName === 'labels') {
    return `{ app = "${moduleName}"; }`;
  }
  if (argName === 'domain') {
    return '"https://example.com"';
  }
  if (argName === 's3Bucket') {
    return '"my-bucket"';
  }
  if (argName === 'port') {
    return '8080';
  }
  if (argName === 'server') {
    return '"10.0.0.10"';
  }
  if (argName === 'path') {
    return '"/srv/data"';
  }

  const nonNullType = typeTokens.find((token) => token !== 'null' && token !== 'unknown');
  const effectiveType = nonNullType || (typeTokens.length === 1 ? typeTokens[0] : null);

  if (effectiveType === 'string') {
    return '"TODO"';
  }
  if (effectiveType === 'number') {
    return argName === 'port' ? '8080' : '0';
  }
  if (effectiveType === 'bool') {
    return 'false';
  }
  if (effectiveType === 'list') {
    return '[ ]';
  }
  if (effectiveType === 'attrset') {
    return '{ }';
  }
  if (effectiveType === 'null') {
    return 'null';
  }

  return '"TODO"';
}

function renderPinnedChartSpec(attrPath, latestVersion, requiredValuesAttrs) {
  const ref = latestVersion ? `version.${toVersionAttr(latestVersion)}` : 'version.latest';
  const lines = [`(${attrPath}.${ref} {`];

  if ((requiredValuesAttrs || []).length > 0) {
    lines.push('  valuesAttrs = {');
    for (const key of requiredValuesAttrs) {
      lines.push(`    ${key} = "TODO";`);
    }
    lines.push('  };');
  } else {
    lines.push('  valuesAttrs = {};');
  }
  lines.push('})');
  return lines.join('\n');
}

function renderCallSpec(attrPath, args) {
  const requiredArgs = args.filter((arg) => arg.required);
  const versionArg = args.find((arg) => arg.name === 'version');
  const lines = [`(${attrPath} {`];

  if (versionArg && versionArg.defaultValue) {
    lines.push(`  version = ${versionArg.defaultValue};`);
  }

  for (const arg of requiredArgs) {
    lines.push(`  ${arg.name} = ${placeholderForRequiredArg(arg, attrPath.split('.').at(-1) || 'item')};`);
  }

  lines.push('})');
  return lines.join('\n');
}

function renderArgType(typeValue) {
  const type = typeof typeValue === 'string' && typeValue.trim() ? typeValue.trim() : 'unknown';
  return `\`${type}\``;
}

function renderArgDefault(defaultValue) {
  if (!defaultValue) {
    return '-';
  }
  return `\`${defaultValue.replaceAll('`', '\\`')}\``;
}

function renderFunctionDocs(lines, fn, headingLevel) {
  const requiredArgs = fn.args.filter((arg) => arg.required);
  const optionalArgs = fn.args.filter((arg) => !arg.required);
  const subHeading = `${headingLevel}#`;

  lines.push(`${headingLevel} ${fn.attrPath}`);
  lines.push('');
  if (Array.isArray(fn.notes) && fn.notes.length > 0) {
    lines.push('::: tip Usage');
    for (let idx = 0; idx < fn.notes.length; idx += 1) {
      lines.push(fn.notes[idx]);
      if (idx < fn.notes.length - 1) {
        lines.push('');
      }
    }
    lines.push(':::');
    lines.push('');
  }

  lines.push(`${subHeading} Copy Call Skeleton`);
  lines.push('');
  lines.push('```nix');
  lines.push(renderCallSpec(fn.attrPath, fn.args));
  lines.push('```');
  lines.push('');
  lines.push(`${subHeading} Required Args`);
  lines.push('');
  lines.push('| Arg | Type | Notes |');
  lines.push('| --- | --- | --- |');
  for (const arg of requiredArgs) {
    lines.push(`| \`${arg.name}\` | ${renderArgType(arg.type)} | ${arg.note || '-'} |`);
  }
  lines.push('');
  lines.push(`${subHeading} Optional Args`);
  lines.push('');
  lines.push('| Arg | Type | Default | Notes |');
  lines.push('| --- | --- | --- | --- |');
  for (const arg of optionalArgs) {
    lines.push(`| \`${arg.name}\` | ${renderArgType(arg.type)} | ${renderArgDefault(arg.defaultValue)} | ${arg.note || '-'} |`);
  }
  lines.push('');
}

function renderNotes(notes) {
  const lines = [];
  if (!notes || notes.length === 0) {
    return lines;
  }
  lines.push('## Notes');
  lines.push('');
  for (const note of notes) {
    lines.push(`- ${note}`);
  }
  lines.push('');
  return lines;
}

function metaSourceLink(value) {
  if (typeof value !== 'string') {
    return null;
  }
  const trimmed = value.trim();
  if (!trimmed) {
    return null;
  }
  return trimmed;
}

function hasOwn(obj, key) {
  return Object.prototype.hasOwnProperty.call(obj || {}, key);
}

function normalizeStringArray(value) {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.filter((item) => typeof item === 'string' && item.trim() !== '').map((item) => item.trim());
}

function parseQuotedNixStrings(input) {
  const matches = input.match(/"(?:(?:\\.)|[^"\\])*"/g) || [];
  const out = [];
  for (const token of matches) {
    try {
      out.push(JSON.parse(token));
    } catch {
      // Skip malformed strings so docs generation keeps working.
    }
  }
  return out;
}

function parseInlineDocsMetaBlock(sourceText) {
  const marker = 'docs_meta =';
  const idx = sourceText.indexOf(marker);
  if (idx < 0) {
    return {};
  }

  const braceStart = sourceText.indexOf('{', idx);
  if (braceStart < 0) {
    return {};
  }

  const braceEnd = findBraceEnd(sourceText, braceStart);
  if (braceEnd < 0) {
    return {};
  }

  const block = sourceText.slice(braceStart + 1, braceEnd);
  const sourceMatch = block.match(/source\s*=\s*("(?:(?:\\.)|[^"\\])*")\s*;/s);
  const notesMatch = block.match(/notes\s*=\s*\[([\s\S]*?)\]\s*;/s);
  const requiredValuesAttrsMatch = block.match(/requiredValuesAttrs\s*=\s*\[([\s\S]*?)\]\s*;/s);

  let source = null;
  if (sourceMatch) {
    try {
      source = JSON.parse(sourceMatch[1]);
    } catch {
      source = null;
    }
  }

  return {
    source,
    notes: notesMatch ? parseQuotedNixStrings(notesMatch[1]) : [],
    requiredValuesAttrs: requiredValuesAttrsMatch ? parseQuotedNixStrings(requiredValuesAttrsMatch[1]) : [],
  };
}

const inlineDocsMetaCache = new Map();

function inlineDocsMetaFromFile(filePath) {
  if (!filePath || !exists(filePath)) {
    return {};
  }
  if (inlineDocsMetaCache.has(filePath)) {
    return inlineDocsMetaCache.get(filePath);
  }

  const sourceText = fs.readFileSync(filePath, 'utf8');
  const parsed = parseInlineDocsMetaBlock(sourceText);
  inlineDocsMetaCache.set(filePath, parsed);
  return parsed;
}

function resolveChartMeta(rowMeta, inlineMeta) {
  const source = hasOwn(rowMeta, 'source') ? metaSourceLink(rowMeta.source) : metaSourceLink(inlineMeta.source);
  const notes = hasOwn(rowMeta, 'notes') ? normalizeStringArray(rowMeta.notes) : normalizeStringArray(inlineMeta.notes);
  const requiredValuesAttrs = hasOwn(rowMeta, 'requiredValuesAttrs')
    ? normalizeStringArray(rowMeta.requiredValuesAttrs)
    : normalizeStringArray(inlineMeta.requiredValuesAttrs);

  return {
    source,
    notes,
    requiredValuesAttrs,
  };
}

function resolveSvcMeta(rowMeta, inlineMeta) {
  const source = hasOwn(rowMeta, 'source') ? metaSourceLink(rowMeta.source) : metaSourceLink(inlineMeta.source);
  const notes = hasOwn(rowMeta, 'notes') ? normalizeStringArray(rowMeta.notes) : normalizeStringArray(inlineMeta.notes);

  return {
    source,
    notes,
  };
}

function buildChartData(meta) {
  const chartMeta = meta.charts || {};
  const jsonFiles = walkFiles(helmRoot, (abs) => abs.endsWith('.json'));
  const byDir = new Map();
  const moduleSourceCache = new Map();

  for (const file of jsonFiles) {
    const dir = path.dirname(file);
    if (!byDir.has(dir)) {
      byDir.set(dir, []);
    }
    byDir.get(dir).push(file);
  }

  const rows = [];
  for (const file of jsonFiles) {
    const dir = path.dirname(file);
    const versionsRaw = JSON.parse(fs.readFileSync(file, 'utf8'));
    const versionEntries = versionsRaw
      .filter((entry) => entry && entry.version)
      .map((entry) => ({
        version: entry.version,
        date: entry.date || null,
        sha256: entry.sha256 || null,
        attr: toVersionAttr(entry.version),
      }))
      .sort(compareVersionEntriesDesc);
    const latestEntry = versionEntries[0] || null;
    const relFromHelm = toPosix(path.relative(helmRoot, file));
    const relFromRepo = relRepo(file);
    const jsonBase = path.basename(file, '.json');
    const moduleDir = toPosix(path.dirname(relFromHelm)).replaceAll('/', '.');
    const siblings = byDir.get(dir) || [];
    const attrPath = siblings.length === 1 ? `hex.k8s.${moduleDir}` : `hex.k8s.${moduleDir}.${jsonBase}`;
    const moduleSource = findChartModuleSource(file);
    const moduleSourceFile = moduleSource ? relRepo(moduleSource) : null;
    let moduleSourceText = null;
    if (moduleSource) {
      if (!moduleSourceCache.has(moduleSource)) {
        moduleSourceCache.set(moduleSource, fs.readFileSync(moduleSource, 'utf8'));
      }
      moduleSourceText = moduleSourceCache.get(moduleSource);
    }
    const inlineMeta = inlineDocsMetaFromFile(moduleSource);
    const rowMeta = chartMeta[attrPath] || {};
    const resolvedMeta = resolveChartMeta(rowMeta, inlineMeta);
    const slug = slugFromAttr(attrPath);
    const helperFunctions = moduleSourceText ? extractChartHelperFunctions(moduleSourceText, attrPath, path.basename(file)) : [];

    rows.push({
      attrPath,
      slug,
      pagePath: `charts/${slug}.md`,
      pageLink: `/reference/charts/${slug}`,
      sourceFile: relFromRepo,
      moduleSourceFile,
      latest: latestEntry?.version ?? null,
      latestDate: latestEntry?.date ?? null,
      latestSha: latestEntry?.sha256 ?? null,
      versionCount: versionEntries.length,
      versions: versionEntries.map((v) => v.version),
      versionEntries,
      valuesUrl: valuesUrlFromDir(dir),
      appSource: resolvedMeta.source,
      requiredValuesAttrs: resolvedMeta.requiredValuesAttrs,
      notes: resolvedMeta.notes,
      helperFunctions,
      helperCount: helperFunctions.length,
    });
  }

  rows.sort((a, b) => a.attrPath.localeCompare(b.attrPath));
  return rows;
}

function buildSvcData(meta) {
  const svcMeta = meta.svc || {};
  const files = walkFiles(svcRoot, (abs) => abs.endsWith('.nix'));
  const rows = [];

  for (const file of files) {
    const source = fs.readFileSync(file, 'utf8');
    let parsedArgs = null;
    const candidates = collectFunctionArgBlocks(source);
    for (const candidate of candidates) {
      const args = parseArgsFromBlock(candidate.block);
      if (args.length === 0) {
        continue;
      }
      const names = args.map((arg) => arg.name);
      const looksLikeImportHeader = names.every((name) => ['hex', 'pkgs', '...'].includes(name));
      if (looksLikeImportHeader) {
        continue;
      }
      parsedArgs = args;
      break;
    }

    if (!parsedArgs) {
      continue;
    }

    const moduleName = path.basename(file, '.nix');
    const attrPath = `hex.k8s.svc.${moduleName}`;
    const slug = moduleName;
    const rowMeta = svcMeta[attrPath] || {};
    const inlineMeta = inlineDocsMetaFromFile(file);
    const resolvedMeta = resolveSvcMeta(rowMeta, inlineMeta);
    const versionArg = parsedArgs.find((arg) => arg.name === 'version');
    const imageTagArg = parsedArgs.find((arg) => arg.name === 'image_tag');

    rows.push({
      moduleName,
      slug,
      attrPath,
      pagePath: `svc/${slug}.md`,
      pageLink: `/reference/svc/${slug}`,
      sourceFile: relRepo(file),
      appSource: resolvedMeta.source,
      args: parsedArgs,
      requiredArgs: parsedArgs.filter((arg) => arg.required).map((arg) => arg.name),
      versionArgDefault: versionArg?.defaultValue || null,
      imageTagDefault: imageTagArg?.defaultValue || null,
      notes: resolvedMeta.notes,
    });
  }

  rows.sort((a, b) => a.attrPath.localeCompare(b.attrPath));
  return rows;
}

function buildHelperData(meta) {
  const helperMeta = meta.helpers || {};
  const modules = [];

  for (const spec of helperSpecs) {
    const sourceText = fs.readFileSync(spec.sourceFile, 'utf8');
    const functions = [];

    for (const fn of spec.functions) {
      const scopeRange = resolveScopeRange(sourceText, fn.scopeChain);
      if (!scopeRange) {
        continue;
      }
      const args = extractFunctionArgsByMarker(sourceText, fn.marker, scopeRange);
      if (!args) {
        continue;
      }
      const markerIndex = sourceText.indexOf(fn.marker, scopeRange.start);
      const fnAttrPath = `${spec.moduleAttrPath}.${fn.name}`;
      const docsNotes = parseDocsNotesBeforeIndex(sourceText, markerIndex);
      const metaNotes = Array.isArray(helperMeta[fnAttrPath]?.notes) ? helperMeta[fnAttrPath].notes : [];
      functions.push({
        name: fn.name,
        attrPath: fnAttrPath,
        args,
        notes: [...docsNotes, ...metaNotes],
      });
    }

    modules.push({
      moduleName: spec.moduleName,
      moduleAttrPath: spec.moduleAttrPath,
      slug: spec.moduleName,
      pagePath: `helpers/${spec.moduleName}.md`,
      pageLink: `/reference/helpers/${spec.moduleName}`,
      sourceFile: relRepo(spec.sourceFile),
      notes: Array.isArray(helperMeta[spec.moduleAttrPath]?.notes) ? helperMeta[spec.moduleAttrPath].notes : [],
      functions,
    });
  }

  modules.sort((a, b) => a.moduleAttrPath.localeCompare(b.moduleAttrPath));
  return modules;
}

function renderChartPage(row) {
  const lines = [
    `# ${row.attrPath}`,
    '',
    `- Latest: \`${row.latest ?? 'n/a'}\``,
    `- Latest date: ${shortDate(row.latestDate) ? `\`${shortDate(row.latestDate)}\`` : 'n/a'}`,
    `- Version count: ${row.versionCount}`,
    `- Source: [json](${githubBlobBase}/${row.sourceFile})${row.moduleSourceFile ? ` [module](${githubBlobBase}/${row.moduleSourceFile})` : ''}`,
    row.valuesUrl ? `- values.yaml: [link](${row.valuesUrl})` : '- values.yaml: not explicitly set in module metadata',
  ];

  if (row.latestSha) {
    lines.push(`- pinned latest sha256: \`${row.latestSha}\``);
  }
  if (row.appSource) {
    lines.push(`- app: [source](${row.appSource})`);
  }
  if (row.requiredValuesAttrs.length > 0) {
    lines.push(`- required valuesAttrs keys: ${row.requiredValuesAttrs.map((k) => `\`${k}\``).join(', ')}`);
  }
  if (row.helperCount > 0) {
    lines.push(`- extra helper functions: ${row.helperCount}`);
  }

  lines.push('');
  lines.push(...renderNotes(row.notes));
  lines.push('## Copy Pinned Spec');
  lines.push('');
  lines.push('```nix');
  lines.push(renderPinnedChartSpec(row.attrPath, row.latest, row.requiredValuesAttrs));
  lines.push('```');
  lines.push('');
  lines.push('## Helper Functions');
  lines.push('');
  if (row.helperFunctions.length === 0) {
    lines.push('No helper functions discovered in this chart module.');
    lines.push('');
  } else {
    for (const fn of row.helperFunctions) {
      renderFunctionDocs(lines, fn, '###');
    }
  }
  lines.push('## Versions');
  lines.push('');
  lines.push('| Version | Date | Attr |');
  lines.push('| --- | --- | --- |');
  for (const version of row.versionEntries) {
    const versionDate = shortDate(version.date);
    const attrRef = `${row.attrPath}.version.${version.attr}`;
    lines.push(`| \`${version.version}\` | ${versionDate ? `\`${versionDate}\`` : '-'} | \`${attrRef}\` |`);
  }
  lines.push('');
  lines.push(`[Back to Chart Index](/reference/chart-index)`);
  lines.push('');
  return `${lines.join('\n')}\n`;
}

function renderSvcPage(row) {
  const requiredArgs = row.args.filter((arg) => arg.required);
  const optionalArgs = row.args.filter((arg) => !arg.required);
  const lines = [
    `# ${row.attrPath}`,
    '',
    `- Source: [module](${githubBlobBase}/${row.sourceFile})`,
    `- Total args: ${row.args.length}`,
  ];

  if (row.versionArgDefault) {
    lines.push(`- default version arg: \`${row.versionArgDefault}\``);
  } else if (row.imageTagDefault) {
    lines.push(`- default image_tag: \`${row.imageTagDefault}\``);
  }
  if (row.appSource) {
    lines.push(`- app: [source](${row.appSource})`);
  }

  lines.push('');
  lines.push(...renderNotes(row.notes));
  lines.push('## Copy Spec Skeleton');
  lines.push('');
  lines.push('```nix');
  lines.push(renderCallSpec(row.attrPath, row.args));
  lines.push('```');
  lines.push('');
  lines.push('## Required Args');
  lines.push('');
  lines.push('| Arg | Notes |');
  lines.push('| --- | --- |');
  for (const arg of requiredArgs) {
    lines.push(`| \`${arg.name}\` | ${arg.note || '-'} |`);
  }
  lines.push('');
  lines.push('## Optional Args');
  lines.push('');
  lines.push('| Arg | Default | Notes |');
  lines.push('| --- | --- | --- |');
  for (const arg of optionalArgs) {
    const defaultValue = arg.defaultValue ? `\`${arg.defaultValue.replaceAll('`', '\\`')}\`` : '-';
    lines.push(`| \`${arg.name}\` | ${defaultValue} | ${arg.note || '-'} |`);
  }
  lines.push('');
  lines.push(`[Back to svc Index](/reference/svc-index)`);
  lines.push('');
  return `${lines.join('\n')}\n`;
}

function renderHelperModulePage(module) {
  const lines = [
    `# ${module.moduleAttrPath}`,
    '',
    `- Source: [module](${githubBlobBase}/${module.sourceFile})`,
    `- Function count: ${module.functions.length}`,
    '',
  ];

  lines.push(...renderNotes(module.notes));

  for (const fn of module.functions) {
    renderFunctionDocs(lines, fn, '##');
  }

  lines.push('[Back to Helper Index](/reference/helpers/index)');
  lines.push('');
  return `${lines.join('\n')}\n`;
}

function renderChartIndex(chartRows) {
  const totalVersions = chartRows.reduce((acc, row) => acc + row.versionCount, 0);
  const lines = [
    '# Chart Index',
    '',
    `Total modules: **${chartRows.length}**`,
    '',
    `Total tracked versions: **${totalVersions}**`,
    '',
    '| Chart | Latest | Latest Date | Versions | Helpers | App | values.yaml | Source |',
    '| --- | --- | --- | --- | --- | --- | --- | --- |',
  ];

  for (const row of chartRows) {
    const chartLink = `[${row.attrPath}](${row.pageLink})`;
    const appCell = row.appSource ? `[app](${row.appSource})` : '-';
    const valuesCell = row.valuesUrl ? `[values.yaml](${row.valuesUrl})` : '-';
    const sourceLinks = `[json](${githubBlobBase}/${row.sourceFile})${row.moduleSourceFile ? ` [module](${githubBlobBase}/${row.moduleSourceFile})` : ''}`;
    const latestDateCell = shortDate(row.latestDate) ? `\`${shortDate(row.latestDate)}\`` : '-';
    lines.push(
      `| ${chartLink} | \`${row.latest ?? 'n/a'}\` | ${latestDateCell} | ${row.versionCount} | ${row.helperCount ?? 0} | ${appCell} | ${valuesCell} | ${sourceLinks} |`,
    );
  }

  lines.push('');
  lines.push('```bash');
  lines.push('nix eval github:jpetrucciani/hex#lib.docsIndex --json');
  lines.push('```');
  lines.push('');
  return `${lines.join('\n')}\n`;
}

function renderSvcIndex(svcRows) {
  const lines = [
    '# svc Index',
    '',
    `Total svc modules: **${svcRows.length}**`,
    '',
    '| Service | Version Arg | Required Args | App | Source |',
    '| --- | --- | --- | --- | --- |',
  ];

  for (const row of svcRows) {
    const svcLink = `[${row.attrPath}](${row.pageLink})`;
    const versionCell = row.versionArgDefault
      ? `\`${row.versionArgDefault}\``
      : row.imageTagDefault
        ? `image_tag: \`${row.imageTagDefault}\``
        : '-';
    const required = row.requiredArgs.length > 0 ? row.requiredArgs.map((x) => `\`${x}\``).join(', ') : '-';
    const appCell = row.appSource ? `[app](${row.appSource})` : '-';
    lines.push(
      `| ${svcLink} | ${versionCell} | ${required} | ${appCell} | [module](${githubBlobBase}/${row.sourceFile}) |`,
    );
  }

  lines.push('');
  return `${lines.join('\n')}\n`;
}

function renderHelperIndex(helperModules) {
  const lines = ['# Helper Index', '', '| Module | Functions | Source |', '| --- | --- | --- |'];

  for (const mod of helperModules) {
    const modLink = `[${mod.moduleAttrPath}](${mod.pageLink})`;
    lines.push(`| ${modLink} | ${mod.functions.length} | [module](${githubBlobBase}/${mod.sourceFile}) |`);
  }

  lines.push('');
  return `${lines.join('\n')}\n`;
}

function renderServicesBuildPage(serviceArgs) {
  const requiredArgs = serviceArgs.filter((arg) => arg.required);
  const optionalArgs = serviceArgs.filter((arg) => !arg.required);
  const lines = [
    '# `hex.k8s.services.build`',
    '',
    `Total args: **${serviceArgs.length}**`,
    '',
    '## Required Args',
    '',
    '| Arg | Notes |',
    '| --- | --- |',
  ];

  for (const arg of requiredArgs) {
    lines.push(`| \`${arg.name}\` | ${arg.note || '-'} |`);
  }

  lines.push('');
  lines.push('## Optional Args');
  lines.push('');
  lines.push('| Arg | Default | Notes |');
  lines.push('| --- | --- | --- |');
  for (const arg of optionalArgs) {
    const defaultValue = arg.defaultValue ? `\`${arg.defaultValue.replaceAll('`', '\\`')}\`` : '-';
    lines.push(`| \`${arg.name}\` | ${defaultValue} | ${arg.note || '-'} |`);
  }

  lines.push('');
  lines.push('## Example');
  lines.push('');
  lines.push('```nix');
  lines.push('{hex}:');
  lines.push('hex [');
  lines.push('  (hex.k8s.services.build {');
  lines.push('    name = "api";');
  lines.push('    labels = {app = "api";};');
  lines.push('    image = "ghcr.io/example/api:latest";');
  lines.push('    port = 8080;');
  lines.push('    ingress = true;');
  lines.push('    host = "api.example.com";');
  lines.push('  })');
  lines.push(']');
  lines.push('```');
  lines.push('');
  return `${lines.join('\n')}\n`;
}

function renderReferenceHome() {
  return `# Reference

The pages in this section are generated during docs build.

- [Chart Index](/reference/chart-index)
- [svc Index](/reference/svc-index)
- [Helper Index](/reference/helpers/index)
- [services.build API](/reference/generated-services-build)
`;
}

function main() {
  ensureDir(docsRefDir);
  ensureMetaFile();
  resetGeneratedDir(chartsDir);
  resetGeneratedDir(svcDir);
  resetGeneratedDir(helpersDir);

  const meta = loadJson(metaFile, { charts: {}, svc: {}, helpers: {} });
  const chartRows = buildChartData(meta);
  const svcRows = buildSvcData(meta);
  const helperModules = buildHelperData(meta);
  const servicesBuildArgs = parseArgsFromBlock(
    (() => {
      const source = fs.readFileSync(servicesFile, 'utf8');
      const marker = 'build =';
      const idx = source.indexOf(marker);
      const braceStart = source.indexOf('{', idx);
      const braceEnd = findBraceEnd(source, braceStart);
      return source.slice(braceStart + 1, braceEnd);
    })(),
  );

  writeFile(path.join(docsRefDir, 'index.md'), renderReferenceHome());
  writeFile(path.join(docsRefDir, 'chart-index.md'), renderChartIndex(chartRows));
  writeFile(path.join(docsRefDir, 'svc-index.md'), renderSvcIndex(svcRows));
  writeFile(path.join(helpersDir, 'index.md'), renderHelperIndex(helperModules));
  writeFile(path.join(docsRefDir, 'generated-services-build.md'), renderServicesBuildPage(servicesBuildArgs));

  for (const row of chartRows) {
    writeFile(path.join(docsRefDir, row.pagePath), renderChartPage(row));
  }
  for (const row of svcRows) {
    writeFile(path.join(docsRefDir, row.pagePath), renderSvcPage(row));
  }
  for (const module of helperModules) {
    writeFile(path.join(docsRefDir, module.pagePath), renderHelperModulePage(module));
  }

  const machineIndex = {
    generatedAt: new Date().toISOString(),
    meta,
    charts: chartRows,
    svc: svcRows.map((row) => ({
      attrPath: row.attrPath,
      pageLink: row.pageLink,
      sourceFile: row.sourceFile,
      args: row.args,
    })),
    helpers: helperModules,
    services: {
      build: {
        sourceFile: relRepo(servicesFile),
        args: servicesBuildArgs,
      },
    },
  };
  writeFile(path.join(docsRefDir, 'generated-k8s-index.json'), `${JSON.stringify(machineIndex, null, 2)}\n`);

  process.stdout.write(
    `generated docs/reference artifacts for ${chartRows.length} charts, ${svcRows.length} svc modules, ${helperModules.length} helper modules\n`,
  );
}

main();
