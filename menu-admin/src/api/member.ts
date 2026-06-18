import { request } from './request'

export interface HealthProfile {
  height?: number
  weight?: number
  age?: number
  gender?: string
  audiences?: string[]
  allergies?: string[]
  sugarMax?: number
  saltMax?: number
  [key: string]: unknown
}

export interface Member {
  id: number
  name: string
  /** 角色标签：逗号分隔的 role 字典 id 字符串（如 "32,34"）。 */
  roleTags: string
  healthProfile: HealthProfile
  /** 小程序功能权限 key 数组（个人勾选；null 走角色默认模板）。 */
  mpPermissions?: string[] | null
}

export interface MemberSaveDTO {
  id?: number
  name: string
  /** 提交时为逗号分隔的 role 字典 id 字符串。 */
  roleTags: string
  healthProfile: HealthProfile
  mpPermissions?: string[] | null
}

export interface MemberPage {
  records: Member[]
  total: number
}

/** 全量功能权限 key -> 中文映射（供表单多选项）。 */
export async function listPermKeys() {
  return request<Record<string, string>>({ url: '/member/permissions/keys', method: 'get' })
}

export function listMembers(params: { pageNum: number; pageSize: number }) {
  return request<MemberPage>({ url: '/member', method: 'get', params })
}

export function createMember(data: MemberSaveDTO) {
  return request<number>({ url: '/member', method: 'post', data })
}

export function updateMember(data: MemberSaveDTO) {
  return request<void>({ url: '/member', method: 'put', data })
}

export function deleteMember(id: number) {
  return request<void>({ url: `/member/${id}`, method: 'delete' })
}
