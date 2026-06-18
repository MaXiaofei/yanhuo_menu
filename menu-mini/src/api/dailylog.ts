import { request } from '@/utils/request'

// 每日饮食记录：某就餐成员某日的摄入日志 + 营养汇总。
export interface DailyLogItemVO {
  id?: number
  logId?: number
  dishId?: number
  ingredientId?: number
  amount?: number
  servingFactor?: number
}

export interface DailyLogVO {
  id: number
  memberId: number
  date: string
  note?: string
  createTime?: string
  items: DailyLogItemVO[]
}

export interface DailyLogSaveItem {
  dishId?: number
  ingredientId?: number
  amount: number
  servingFactor?: number
}

export interface DailyLogSaveDTO {
  date: string
  note?: string
  items?: DailyLogSaveItem[]
}

// 提交当天日志（session memberId 由后端取）。返回 logId。
export const submitDailyLog = (data: DailyLogSaveDTO) =>
  request<number>({ url: '/dailylog', method: 'POST', data })

// 查当天日志（含 items）。无则返回 null。
export const getDailyLog = (date: string) =>
  request<DailyLogVO | null>({ url: '/dailylog', method: 'GET', data: { date } })

// 总营养汇总：后端返回 Map<指标id, 值>。
export const dailyLogNutrition = (logId: number) =>
  request<Record<string, number>>({ url: `/dailylog/${logId}/nutrition`, method: 'GET' })
