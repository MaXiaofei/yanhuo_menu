import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

// menu-mini 单元测试配置。
// 注意：不引入 @dcloudio/vite-plugin-uni（它会注入 uni-app 编译期依赖，单测环境无法运行），
// 纯逻辑测试只依赖 vue 插件 + alias + setup.ts 全局 mock uni。
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./test/setup.ts'],
    include: ['test/**/*.{test,spec}.ts'],
  },
})
