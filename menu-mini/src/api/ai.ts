import { request } from '@/utils/request'

// V2 AI 入口（后端 mock，待接 GLM）
// memberId 后端从 session 取，前端不传（需登录 + 设当前就餐成员 @MpPerm("ai.use")）

export interface AiNutritionItem {
  metricId: number
  value: number
}
export interface AiNutritionFillResult {
  nutrition: AiNutritionItem[]
  source: string // "mock"
}

/** AI 补全营养：输入食材名 → 返回 6 项 per100g（metricId+value），source=mock 待接 GLM */
export const aiFillNutrition = (name: string) =>
  request<AiNutritionFillResult>({ url: '/ai/nutrition/fill', method: 'POST', data: { name } })

export interface AiRecommendDish {
  dishId: number
  name: string
  servingFactor?: number
  price?: number
}
export interface AiRecommendGroup {
  dishes: AiRecommendDish[]
  totalPrice: number
  totalNutrition: Record<string, number> // metricId -> value
  score?: number
  reasons?: string[]
  source?: string
}

/** AI 推荐菜单：budget/scope(DAY|WEEK)/筛选条件 → 候选组（memberId 后端 session 取） */
export const aiRecommendMenu = (params: {
  budget?: number
  scope?: 'DAY' | 'WEEK'
  cuisineIds?: number[]
  tagIds?: number[]
  categoryIds?: number[]
  maxMinutes?: number
  maxDifficulty?: number
}) => request<AiRecommendGroup[]>({ url: '/ai/menu/recommend', method: 'POST', data: { ...params } })

// V2 方案2：文字描述 → AI 估算该餐总营养
export interface AiDishEstimateResult {
  description: string
  /** metricId(数字) -> 估算总量 */
  nutrition: Record<string, number>
  source: string // "deepseek" | "mock"
  aiNote: string
}

/** AI 估算菜品/一餐营养：文字描述（如"一盘番茄炒蛋,2个鸡蛋2个番茄"）+ 份数 → 总营养 */
export const aiEstimateDish = (description: string, servingFactor?: number) =>
  request<AiDishEstimateResult>({
    url: '/ai/dish/estimate',
    method: 'POST',
    data: servingFactor ? { description, servingFactor } : { description },
  })
