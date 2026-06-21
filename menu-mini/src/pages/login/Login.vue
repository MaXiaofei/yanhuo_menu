<template>
  <view class="login">
    <view class="logo">小食单</view>
    <view class="field-label">手机号 / 账号</view>
    <u-input
      v-model="form.username"
      placeholder="手机号 或 admin"
      border="surround"
      clearable
    />
    <view class="field-label">密码</view>
    <u-input
      v-model="form.password"
      type="password"
      placeholder="密码"
      border="surround"
      clearable
    />
    <u-button type="primary" :loading="loading" @click="onLogin">登录</u-button>
  </view>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useAuthStore } from '@/store/auth'

const auth = useAuthStore()
// 默认空,引导用户输自己的手机号;老 admin 仍可填 admin 登录
const form = reactive({ username: '', password: '' })
const loading = ref(false)

async function onLogin() {
  if (!form.username || !form.password) {
    uni.showToast({ title: '请输入手机号/账号和密码', icon: 'none' })
    return
  }
  loading.value = true
  try {
    // 合并后:登录即定就餐成员,后端 session.currentMemberId = loginId,无需切成员
    await auth.login(form.username, form.password)
    uni.switchTab({ url: '/pages/index/Index' })
  } catch {
    // request.ts 已弹 toast，这里不重复
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login {
  padding: 40rpx;
}
.logo {
  font-size: 48rpx;
  font-weight: bold;
  text-align: center;
  color: #ff8c42;
  margin: 60rpx 0;
}
.u-input {
  margin-top: 8rpx;
}
.field-label {
  margin-top: 24rpx;
  font-size: 26rpx;
  color: #7a6f60;
}
.u-button {
  margin-top: 24rpx;
}
</style>
