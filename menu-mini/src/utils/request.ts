const BASE = '/api' // H5 走 vite proxy；小程序/真机改成 http://<host>:8080

export function getToken(): string {
  return uni.getStorageSync('token') || ''
}

export async function request<T = any>(opt: UniApp.RequestOptions): Promise<T> {
  const res: any = await uni.request({
    ...opt,
    url: BASE + opt.url,
    header: { Authorization: getToken(), ...opt.header }
  })
  const body = res.data // 后端统一 R{code,msg,data}
  if (body.code === 401) {
    uni.removeStorageSync('token')
    uni.reLaunch({ url: '/pages/login/Login' })
    throw new Error('未登录')
  }
  if (body.code !== 0) {
    uni.showToast({ title: body.msg || '请求失败', icon: 'none' })
    throw new Error(body.msg)
  }
  return body.data as T
}
