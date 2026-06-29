import { test, expect, type Route } from '@playwright/test'

// 登录流程 E2E：用 route mock 拦截后端，避免依赖真实服务。
// 用正则 /\/gudu\// 精确匹配浏览器发出的相对/绝对路径请求。
test.describe('登录流程', () => {
  test('未登录访问根路径 → 重定向到登录页', async ({ page }) => {
    await page.goto('/')
    await expect(page).toHaveURL(/\/login$/)
    await expect(page.getByText('小食单')).toBeVisible()
  })

  test('登录成功 → 跳转首页', async ({ page }) => {
    // mock 登录接口（精确匹配）
    await page.route(/\/auth\/login$/, async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ code: 0, msg: 'ok', data: { token: 'e2e-token', nickname: 'E2E管理员' } }),
      })
    })
    // 其它 /gudu 请求兜底（首页等）
    await page.route(/\/gudu\//, async (route: Route) => {
      if (route.request().url().includes('/auth/login')) {
        await route.fulfill({ status: 200, contentType: 'application/json', body: '{"code":0,"msg":"ok","data":{"token":"e2e-token","nickname":"E2E管理员"}}' })
        return
      }
      await route.fulfill({ status: 200, contentType: 'application/json', body: '{"code":0,"msg":"ok","data":{}}' })
    })

    await page.goto('/login')
    // 用户名/密码默认已填 admin/admin123，直接点登录
    await page.getByRole('button', { name: /登.*录/ }).click()

    await expect(page).toHaveURL(/\/home$/, { timeout: 10000 })
  })

  test('错误密码 → 提示错误且停留在登录页', async ({ page }) => {
    await page.route(/\/auth\/login$/, async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ code: 1, msg: '用户名或密码错误', data: null }),
      })
    })

    await page.goto('/login')
    await page.getByRole('button', { name: /登.*录/ }).click()

    // 留在登录页
    await expect(page).toHaveURL(/\/login$/)
  })
})
