import { BASE, getToken } from '@/utils/request'

/**
 * 文件上传公共 helper。
 *
 * 后端：POST /file/upload，multipart，返回单个 URL（String）。
 * header 需带 Sa-Token。与 review.ts 中原 uploadImages 逻辑一致，抽公共以便复用。
 */

/** 单图上传：立即传，返回 URL。供「选完即传」使用。 */
export async function uploadOne(filePath: string): Promise<string> {
  return new Promise((resolve, reject) => {
    uni.uploadFile({
      url: BASE + '/file/upload',
      filePath,
      name: 'file',
      header: { Authorization: getToken() },
      success: (res) => {
        try {
          const body = JSON.parse(res.data)
          // 后端统一返回 { code, msg, data }，data 为 URL
          if (body && body.code === 0) {
            resolve(body.data)
            return
          }
          // 兼容直接返回 URL 字符串
          if (typeof body === 'string') {
            resolve(body)
            return
          }
          reject(new Error(body?.msg || '上传失败'))
        } catch {
          reject(new Error('上传响应解析失败'))
        }
      },
      fail: (err) => reject(err),
    })
  })
}

/** 多图批量上传：逐张传，全部完成后返回 URL 数组（保持顺序）。 */
export async function uploadImages(filePaths: string[]): Promise<string[]> {
  const urls: string[] = []
  for (const p of filePaths) {
    urls.push(await uploadOne(p))
  }
  return urls
}
