import { defineConfig, devices } from '@playwright/test'

// Playwright E2E（H5 端）：先构建 H5 产物，再对预览 server 跑端到端。
// 小程序原生 E2E 需微信开发者工具/HBuilderX，CI 无法运行，故采用 H5 端覆盖。
// 运行：npm run test:e2e:h5
export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:4174',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    // 用 python 内置静态 server 托管 uni-app H5 产物（vite preview 的 --root 选项在此版本不支持）
    command: 'python3 -m http.server 4174 --directory dist/build/h5',
    url: 'http://localhost:4174',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
})
