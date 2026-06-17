import { request } from '@/utils/request'

export const searchDishes = (params: Record<string, any>) =>
  request<any>({ url: '/dish/search', method: 'GET', data: params })
