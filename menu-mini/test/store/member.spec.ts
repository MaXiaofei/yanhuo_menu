import { describe, it, expect, vi, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'

// mock @/api/member（依赖 request，整体接管）
const listMembers = vi.fn()
const setCurrentMember = vi.fn()
const getCurrentMember = vi.fn()
vi.mock('@/api/member', () => ({
  listMembers: (...a: any[]) => listMembers(...a),
  setCurrentMember: (...a: any[]) => setCurrentMember(...a),
  getCurrentMember: (...a: any[]) => getCurrentMember(...a),
}))

const { useMemberStore } = await import('@/store/member')

describe('store/member', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    listMembers.mockReset()
    setCurrentMember.mockReset()
    getCurrentMember.mockReset()
  })

  describe('初始状态', () => {
    it('currentId=0、members 空', () => {
      const store = useMemberStore()
      expect(store.currentId).toBe(0)
      expect(store.members).toEqual([])
    })
  })

  describe('load', () => {
    it('加载成员列表 + 当前成员', async () => {
      listMembers.mockResolvedValue([
        { id: 1, name: '张爸爸' },
        { id: 2, name: '张妈妈' },
      ])
      getCurrentMember.mockResolvedValue(1)

      const store = useMemberStore()
      await store.load()

      expect(store.members).toHaveLength(2)
      expect(store.members[0].name).toBe('张爸爸')
      expect(store.currentId).toBe(1)
    })

    it('getCurrentMember 返回空时 currentId 兜底 0', async () => {
      listMembers.mockResolvedValue([])
      getCurrentMember.mockResolvedValue(0)

      const store = useMemberStore()
      await store.load()

      expect(store.currentId).toBe(0)
    })

    it('getCurrentMember 返回 falsy（null）时 currentId 兜底 0', async () => {
      listMembers.mockResolvedValue([])
      getCurrentMember.mockResolvedValue(null as any)

      const store = useMemberStore()
      await store.load()

      expect(store.currentId).toBe(0)
    })
  })

  describe('switchTo', () => {
    it('切换成员 → 调 setCurrentMember + 更新 currentId', async () => {
      setCurrentMember.mockResolvedValue(undefined)

      const store = useMemberStore()
      await store.switchTo(5)

      expect(setCurrentMember).toHaveBeenCalledWith(5)
      expect(store.currentId).toBe(5)
    })
  })
})
