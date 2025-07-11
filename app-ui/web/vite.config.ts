import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'



// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  root: "./",
  build: {
      outDir: "../api/static",
      emptyOutDir: true,
      sourcemap: true,
      rollupOptions: {
          output: {
              manualChunks: id => {
                  if (id.includes("node_modules")) {
                      return "vendor";
                  }
              }
          }
      }
  },
  server: {
    host: '127.0.0.1',
    watch: {
      usePolling: true,
      interval: 100, // Poll every 100ms
    },
      proxy: {
          "/about": {target: "http://127.0.0.1:5000", changeOrigin: true},
          "/heartbeatwebapp": {target: "http://127.0.0.1:5000", changeOrigin: true}
      }
  }
});
