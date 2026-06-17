<template>
  <view class="list">
    <u-search v-model="keyword" placeholder="搜菜名" @search="reload" @clear="reload" />
    <u-cell
      v-for="d in dishes"
      :key="d.id"
      :title="d.name"
      :label="`${d.cookTime || 0}分钟 · 难度${d.difficulty || '-'}`"
      isLink
      @click="goDetail(d.id)"
    />
    <view v-if="dishes.length === 0" class="empty">暂无菜品</view>
    <u-loadmore :status="status" />
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { onReachBottom, onPullDownRefresh } from '@dcloudio/uni-app'
import { searchDishes } from '@/api/dish'

const dishes = ref<any[]>([])
const keyword = ref('')
const page = ref(1)
const pageSize = 20
const status = ref<'loadmore' | 'loading' | 'nomore'>('loadmore')

async function reload() {
  page.value = 1
  dishes.value = []
  await load()
}

async function load() {
  status.value = 'loading'
  try {
    const r = await searchDishes({ keyword: keyword.value, pageNum: page.value, pageSize })
    const records = Array.isArray(r) ? r : (r.records || [])
    dishes.value.push(...records)
    status.value = records.length < pageSize ? 'nomore' : 'loadmore'
  } catch {
    status.value = 'loadmore'
  }
}

onPullDownRefresh(() => {
  reload().finally(() => uni.stopPullDownRefresh())
})
onReachBottom(() => {
  if (status.value === 'loadmore') {
    page.value++
    load()
  }
})

reload()
function goDetail(id: number) {
  // dish/Detail 由 B5 建页面并注册 pages.json；当前未建，navigateTo 会失败但不影响列表
  try {
    uni.navigateTo({ url: `/pages/dish/Detail?id=${id}`, fail: () => uni.showToast({ title: '详情页未就绪', icon: 'none' }) })
  } catch {
    uni.showToast({ title: '详情页未就绪', icon: 'none' })
  }
}
</script>

<style scoped>
.list { padding: 20rpx; }
.empty { text-align: center; color: #999; padding: 60rpx 0; }
</style>
