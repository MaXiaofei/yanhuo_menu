import { describe, it, expect } from 'vitest'
import { themes, getTheme } from './themes'

describe('themes 数据', () => {
  it('至少包含 warm / green 两个主题', () => {
    const keys = themes.map((t) => t.key)
    expect(keys).toContain('warm')
    expect(keys).toContain('green')
  })

  it('每个主题字段完整（key/name/primary/sidebar/bg）', () => {
    for (const t of themes) {
      expect(t.key).toBeTruthy()
      expect(t.name).toBeTruthy()
      expect(t.primary).toMatch(/^#/)
      expect(t.sidebar).toMatch(/^#/)
      expect(t.bg).toMatch(/^#/)
    }
  })
})

describe('getTheme', () => {
  it('已知 key 返回对应主题', () => {
    expect(getTheme('warm').key).toBe('warm')
    expect(getTheme('green').key).toBe('green')
  })

  it('未知 key fallback 到 themes[0]（warm）', () => {
    expect(getTheme('not-exist').key).toBe(themes[0].key)
  })

  it('空串 fallback 到 themes[0]', () => {
    expect(getTheme('').key).toBe(themes[0].key)
  })
})
