import footnote from 'markdown-it-footnote';
import { defineConfig } from 'vitepress';

export default defineConfig({
  title: 'hex 🪄',
  description: 'Nix-powered k8s configuration magic',
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Getting Started', link: '/getting-started' },
      { text: 'Examples', link: '/basic-examples' },
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
