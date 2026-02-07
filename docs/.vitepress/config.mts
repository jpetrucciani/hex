import footnote from 'markdown-it-footnote';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { defineConfig } from 'vitepress';

const docsRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const generatedIndexPath = path.join(docsRoot, 'reference', 'generated-k8s-index.json');

type SidebarLeaf = {
  text: string;
  link: string;
};

type SidebarGroup = {
  text: string;
  collapsed?: boolean;
  items: SidebarLeaf[];
};

function loadGeneratedIndex():
  | {
      charts?: Array<{ attrPath?: string; pageLink?: string }>;
      svc?: Array<{ attrPath?: string; pageLink?: string }>;
      helpers?: Array<{ moduleAttrPath?: string; pageLink?: string }>;
    }
  | null {
  try {
    const raw = fs.readFileSync(generatedIndexPath, 'utf8');
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function sortByText(a: SidebarLeaf, b: SidebarLeaf): number {
  return a.text.localeCompare(b.text);
}

const generatedIndex = loadGeneratedIndex();
const chartItems: SidebarLeaf[] = (generatedIndex?.charts || [])
  .filter((entry) => entry.attrPath && entry.pageLink)
  .map((entry) => ({
    text: entry.attrPath || '',
    link: entry.pageLink || '',
  }))
  .sort(sortByText);

const svcItems: SidebarLeaf[] = (generatedIndex?.svc || [])
  .filter((entry) => entry.attrPath && entry.pageLink)
  .map((entry) => ({
    text: entry.attrPath || '',
    link: entry.pageLink || '',
  }))
  .sort(sortByText);

const helperItems: SidebarLeaf[] = (generatedIndex?.helpers || [])
  .filter((entry) => entry.moduleAttrPath && entry.pageLink)
  .map((entry) => ({
    text: entry.moduleAttrPath || '',
    link: entry.pageLink || '',
  }))
  .sort(sortByText);

const referenceItems: Array<SidebarLeaf | SidebarGroup> = [
  { text: 'Reference Home', link: '/reference/index' },
  { text: 'Chart Index', link: '/reference/chart-index' },
];

if (chartItems.length > 0) {
  referenceItems.push({
    text: 'Charts',
    collapsed: true,
    items: chartItems,
  });
}

referenceItems.push({ text: 'svc Index', link: '/reference/svc-index' });

if (svcItems.length > 0) {
  referenceItems.push({
    text: 'svc Modules',
    collapsed: true,
    items: svcItems,
  });
}

referenceItems.push({ text: 'Helper Index', link: '/reference/helpers/index' });

if (helperItems.length > 0) {
  referenceItems.push({
    text: 'Helpers',
    collapsed: true,
    items: helperItems,
  });
}

referenceItems.push({ text: 'services.build API', link: '/reference/generated-services-build' });

export default defineConfig({
  title: 'hex 🪄',
  description: 'Nix-powered k8s configuration magic',
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Getting Started', link: '/getting-started' },
      { text: 'Examples', link: '/basic-examples' },
      { text: 'Reference', link: '/reference/index' },
    ],
    sidebar: [
      {
        text: 'Introduction',
        items: [
          { text: 'Getting Started', link: '/getting-started' },
          { text: 'What is hex?', link: '/what-is-hex' },
        ],
      },
      {
        text: 'Examples',
        items: [
          { text: 'Basic Example', link: '/basic-examples' },
          { text: 'More Examples', link: '/more-examples' },
          { text: 'Full Spec', link: '/specs' },
        ],
      },
      {
        text: 'Integrations',
        items: [
          { text: 'ArgoCD', link: '/integration-argocd' },
          { text: 'Helm', link: '/integration-helm' },
        ],
      },
      {
        text: 'Reference',
        items: referenceItems,
      },
    ],
    socialLinks: [{ icon: 'github', link: 'https://github.com/jpetrucciani/hex' }],
    search: {
      provider: 'local',
    },
  },
  markdown: {
    config: (md) => {
      md.use(footnote);
    },
  },
  cleanUrls: true,
  sitemap: {
    hostname: 'https://hex.gemologic.dev',
    lastmodDateOnly: false,
  },
});
