import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  css: {
    /* isolate from the parent repo's PostCSS/Tailwind config */
    postcss: { plugins: [] },
  },
  build: {
    target: "es2020",
    cssMinify: true,
  },
});
