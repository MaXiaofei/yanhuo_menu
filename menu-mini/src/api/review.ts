import { request } from '@/utils/request'
// 图片上传抽到公共 helper，避免重复（顺带修掉旧实现里 r.url 取错字段的 bug）
export { uploadImages } from '@/api/upload'

export const submitReview = (data: any) => request({ url: '/review', method: 'POST', data })
export const listByDish = (dishId: number) => request<any[]>({ url: `/review/dish/${dishId}`, method: 'GET' })
export const reviewAvg = (dishId: number) => request<any>({ url: `/review/dish/${dishId}/avg`, method: 'GET' })
export const dimensions = () => request<any[]>({ url: '/dict?group=review_dimension', method: 'GET' })
