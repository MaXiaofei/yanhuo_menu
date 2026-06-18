import { request } from './request'

// 采购清单（从周计划聚合：合并同食材同单位 → 品类分区）
export interface ShoppingItemVO {
  id: number
  listId?: number
  ingredientId: number
  ingredientName?: string
  totalAmount: number
  unitId?: number
  unitName?: string
  purchaseCategoryId?: number
  purchaseCategoryName?: string
  purchased?: number // 0 未买 / 1 已买
  [key: string]: unknown
}

export interface ShoppingListVO {
  id: number
  sourcePlanId?: number
  timeRange?: string
  startDate?: string
  endDate?: string
  createdAt?: string
  items: ShoppingItemVO[]
  grouped?: Record<string, ShoppingItemVO[]>
  categoryNames?: Record<string, string>
  [key: string]: unknown
}

export interface ShoppingList {
  id: number
  sourcePlanId?: number
  timeRange?: string
  startDate?: string
  endDate?: string
  createdAt?: string
  [key: string]: unknown
}

export interface ShoppingListPage {
  records: ShoppingList[]
  total: number
}

export function listShopping(params: { pageNum: number; pageSize: number }) {
  return request<ShoppingListPage>({ url: '/shopping', method: 'get', params })
}

export function getShoppingDetail(listId: number) {
  return request<ShoppingListVO>({ url: `/shopping/${listId}`, method: 'get' })
}

export function generateShopping(planId: number, timeRange = 'week') {
  return request<number>({ url: '/shopping/generate', method: 'post', params: { planId, timeRange } })
}

export function togglePurchased(itemId: number) {
  return request<void>({ url: `/shopping/item/${itemId}/purchased`, method: 'put' })
}

export function deleteShoppingItem(itemId: number) {
  return request<void>({ url: `/shopping/item/${itemId}`, method: 'delete' })
}

export function deleteShoppingList(listId: number) {
  return request<void>({ url: `/shopping/${listId}`, method: 'delete' })
}
