import path from 'path';
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import yaml from '@rollup/plugin-yaml';
import { aliases, vueOptions } from './vite.shared';

// Standalone Vite app that renders the component stories (replaces Histoire).
// It reuses the dashboard aliases/plugins but drops vite-plugin-ruby, which is
// specific to the Rails asset pipeline and not needed here.
export default defineConfig({
  root: path.resolve('app/javascript/stories'),
  plugins: [vue(vueOptions), yaml()],
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern-compiler',
      },
    },
  },
  resolve: { alias: aliases },
  server: {
    port: 6179,
    fs: { allow: [path.resolve('.')] },
  },
  build: {
    outDir: path.resolve('.stories'),
    emptyOutDir: true,
  },
});
