import { defineStore } from 'pinia'
import { listMembers, setCurrentMember, getCurrentMember } from '@/api/member'

export const useMemberStore = defineStore('member', {
  state: () => ({
    currentId: 0 as number,
    members: [] as any[]
  }),
  actions: {
    async load() {
      this.members = await listMembers()
      const cur = await getCurrentMember()
      this.currentId = cur || 0
    },
    async switchTo(id: number) {
      await setCurrentMember(id)
      this.currentId = id
    }
  }
})
