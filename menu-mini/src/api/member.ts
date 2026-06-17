import { request } from '@/utils/request'

export const listMembers = () => request<any[]>({ url: '/member', method: 'GET' })

export const setCurrentMember = (memberId: number) =>
  request({ url: `/member/current?memberId=${memberId}`, method: 'POST' })

export const getCurrentMember = () =>
  request<number>({ url: '/member/current', method: 'GET' })
