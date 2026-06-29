import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import { fileURLToPath, URL } from 'node:url';
export default defineConfig({
    plugins: [vue()],
    resolve: {
        alias: {
            '@': fileURLToPath(new URL('./src', import.meta.url)),
        },
    },
    server: {
        host: '0.0.0.0',
        port: 5173,
        proxy: {
            '/gudu': {
                target: 'http://localhost:8080',
                changeOrigin: true,
                // 后端 context-path=/gudu，直接透传，无需 rewrite
            },
        },
    },
});
