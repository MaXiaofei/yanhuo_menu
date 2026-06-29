import { test, expect } from '@playwright/test'

// 采购列表 H5 冒烟 E2E：注入登录态后访问采购列表，mock 接口验证渲染。
test.beforeEach(async ({ page }) => {
  // uni-app H5 下 uni storage 落到 localStorage，注入 token 模拟登录态
  await page.addInitScript(() => {
    localStorage.setItem('token', 'h5-token')
  })
})

test.describe('H5 采购列表', () => {
  test('注入登录态 → 访问采购列表 → 渲染空态或列表', async ({ page }) => {
    await page.route(/\/gudu\//, async (route) => {
      const url = route.request().url()
      // 采购列表接口返回空
      if (url.includes('/shopping')) {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({ code: 0, msg: 'ok', data: [] }),
        })
        return
      }
      await route.fulfill({ status: 200, contentType: 'application/json', body: '{"code":0,"msg":"ok","data":{}}' })
    })

    // 直接导航到采购列表 hash 路由
    await page.goto('/#/pages/shopping/List')
    // 空态文案「还没有采购记录」应出现
    await expect(page.getByText('还没有采购记录')).toBeVisible({ timeout: 10000 })
  })
})
