/// <reference types="@dcloudio/types" />
import { vi } from 'vitest'

// 全局 mock uni 对象（uni-app 运行时 API）。
// 用内存 Map 模拟 storage，记录 reLaunch/toast 调用便于断言。

const storage = new Map<string, any>()

const uniMock = {
  // ---- storage ----
  getStorageSync(key: string): any {
    return storage.has(key) ? storage.get(key) : ''
  },
  setStorageSync(key: string, data: any): void {
    storage.set(key, data)
  },
  removeStorageSync(key: string): void {
    storage.delete(key)
  },
  clearStorageSync(): void {
    storage.clear()
  },
  // ---- 导航 ----
  reLaunch: vi.fn(),
  navigateTo: vi.fn(),
  redirectTo: vi.fn(),
  switchTab: vi.fn(),
  // ---- UI ----
  showToast: vi.fn(),
  showLoading: vi.fn(),
  hideLoading: vi.fn(),
  showModal: vi.fn(),
  // ---- 网络 ----
  request: vi.fn(),
}

;(globalThis as any).uni = uniMock

// 暴露给测试用：重置 storage 与 spy 调用记录
export const __testUni = {
  resetStorage() {
    storage.clear()
  },
  setStorage(key: string, data: any) {
    storage.set(key, data)
  },
  getStorage(key: string) {
    return storage.get(key)
  },
  mocks: uniMock,
}
