import { defineConfig } from "vite";
import uni from "@dcloudio/vite-plugin-uni";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [uni()],
  server: {
    proxy: {
      '/gudu': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        // 后端 context-path=/gudu，直接透传，无需 rewrite
      }
    }
  }
});
