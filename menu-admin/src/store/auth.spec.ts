import { describe, it, expect, vi, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'

// mock @/api/auth：可控 login/logout/me 的返回与抛错
const apiLogin = vi.fn()
const apiLogout = vi.fn()
const apiMe = vi.fn()
vi.mock('@/api/auth', () => ({
  login: (...args: any[]) => apiLogin(...args),
  logout: (...args: any[]) => apiLogout(...args),
  me: (...args: any[]) => apiMe(...args),
}))

const { useAuthStore } = await import('./auth')

describe('useAuthStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    localStorage.clear()
    apiLogin.mockReset()
    apiLogout.mockReset()
    apiMe.mockReset()
  })

  describe('login', () => {
    it('成功 → 写 token/nickname 到 state 和 localStorage', async () => {
      apiLogin.mockResolvedValue({ token: 'tok1', nickname: '张爸爸' })
      const store = useAuthStore()

      await store.login({ username: 'admin', password: '123' })

      expect(store.token).toBe('tok1')
      expect(store.nickname).toBe('张爸爸')
      expect(localStorage.getItem('gudu-token')).toBe('tok1')
      expect(localStorage.getItem('gudu-nickname')).toBe('张爸爸')
    })

    it('透传 dto 给 apiLogin', async () => {
      apiLogin.mockResolvedValue({ token: 't', nickname: 'n' })
      const store = useAuthStore()
      const dto = { username: 'u', password: 'p' }
      await store.login(dto)
      expect(apiLogin).toHaveBeenCalledWith(dto)
    })
  })

  describe('logout', () => {
    it('成功 → 清空 state 和 localStorage', async () => {
      apiLogout.mockResolvedValue(undefined)
      const store = useAuthStore()
      store.token = 'tok'
      store.nickname = 'n'
      localStorage.setItem('gudu-token', 'tok')
      localStorage.setItem('gudu-nickname', 'n')

      await store.logout()

      expect(store.token).toBe('')
      expect(store.nickname).toBe('')
      expect(localStorage.getItem('gudu-token')).toBeNull()
      expect(localStorage.getItem('gudu-nickname')).toBeNull()
    })

    it('apiLogout 抛错 → 仍清本地态（容错分支）', async () => {
      apiLogout.mockRejectedValue(new Error('网络错误'))
      const store = useAuthStore()
      store.token = 'tok'
      store.nickname = 'n'
      localStorage.setItem('gudu-token', 'tok')
      localStorage.setItem('gudu-nickname', 'n')

      // 即使后端 logout 报错，本地态也必须被清理（不能残留登录态）
      await store.logout()

      expect(store.token).toBe('')
      expect(store.nickname).toBe('')
      expect(localStorage.getItem('gudu-token')).toBeNull()
      expect(localStorage.getItem('gudu-nickname')).toBeNull()
    })
  })

  describe('fetchMe', () => {
    it('透传调用 apiMe 并返回 id', async () => {
      apiMe.mockResolvedValue(1)
      const store = useAuthStore()
      const id = await store.fetchMe()
      expect(id).toBe(1)
      expect(apiMe).toHaveBeenCalled()
    })
  })

  describe('初始状态', () => {
    it('localStorage 有 token 时初始化恢复', () => {
      localStorage.setItem('gudu-token', 'restored')
      localStorage.setItem('gudu-nickname', 'restored-nick')
      const store = useAuthStore()
      expect(store.token).toBe('restored')
      expect(store.nickname).toBe('restored-nick')
    })

    it('localStorage 无 token 时初始为空串', () => {
      const store = useAuthStore()
      expect(store.token).toBe('')
      expect(store.nickname).toBe('')
    })
  })
})
