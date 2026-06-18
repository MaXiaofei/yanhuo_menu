import { request } from './request'

export interface DictItem {
  id: number
  dictGroup: string
  name: string
  sort: number
}

export interface DictSaveDTO {
  id?: number
  dictGroup: string
  name: string
  sort: number
}

export interface DictPage {
  records: DictItem[]
  total: number
}

/** 拉取某个 group 下的字典项（全量，下拉选项用，内部取大页）。 */
export function listByGroup(group: string) {
  return request<DictPage>({ url: '/dict', method: 'get', params: { group, pageNum: 1, pageSize: 1000 } }).then(
    (p) => p.records,
  )
}

/** 拉取某个 group 下的字典项（分页，列表页用）。 */
export function listDictPaged(group: string, params: { pageNum: number; pageSize: number }) {
  return request<DictPage>({ url: '/dict', method: 'get', params: { group, ...params } })
}

export function createDict(data: DictSaveDTO) {
  return request<number>({ url: '/dict', method: 'post', data })
}

export function updateDict(data: DictSaveDTO) {
  return request<void>({ url: '/dict', method: 'put', data })
}

export function deleteDict(id: number) {
  return request<void>({ url: `/dict/${id}`, method: 'delete' })
}

// 营养指标（独立资源，挂在配置中心一起管）
export interface NutritionMetric {
  id: number
  name: string
  unit: string
  metricGroup: string
}

export function listNutritionMetrics() {
  return request<NutritionMetric[]>({ url: '/nutrition/metric', method: 'get' })
}
