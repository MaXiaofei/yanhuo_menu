<template>
  <view class="page">
    <!-- 顶栏：大标题 + 齿轮 -->
    <view class="topbar">
      <view class="title-wrap">
        <view class="title-bar"></view>
        <text class="title">我的菜</text>
      </view>
      <view class="top-actions">
        <text class="ico-btn" @click="toggleSearch">🔍</text>
        <text class="ico-btn" @click="goSettings">⚙️</text>
      </view>
    </view>

    <!-- 搜索（默认收起） -->
    <view v-if="searchOpen" class="search-box">
      <text class="s-ico">🔍</text>
      <input
        class="s-input"
        v-model="keyword"
        placeholder="搜菜名"
        placeholder-class="s-ph"
        confirm-type="search"
        @confirm="reload"
      />
      <text v-if="keyword" class="s-clear" @click="clearKeyword">✕</text>
    </view>

    <!-- 分类标签横滑 -->
    <scroll-view scroll-x class="cat-scroll" :show-scrollbar="false">
      <view class="cat-row">
        <view
          v-for="c in cats"
          :key="c.key"
          :class="['cat-chip', activeCat === c.key ? 'on' : '']"
          @click="onCat(c.key)"
        >
          {{ c.label }}
        </view>
      </view>
    </scroll-view>

    <!-- 筛选折叠（营养/难度，保留） -->
    <view class="filter-toggle" @click="showFilter = !showFilter">
      <text>{{ showFilter ? '收起筛选' : '筛选' }}</text>
      <text v-if="activeFilterCount" class="badge">{{ activeFilterCount }}</text>
    </view>

    <view v-if="showFilter" class="yh-card filter-panel">
      <view class="f-title">营养上限（每份不超）</view>
      <view class="f-grid">
        <view class="f-cell">
          <text class="f-label">糖≤(g)</text>
          <input class="f-input" type="digit" v-model="filters.sugar" placeholder="如25" />
        </view>
        <view class="f-cell">
          <text class="f-label">GI≤</text>
          <input class="f-input" type="digit" v-model="filters.gi" placeholder="如55" />
        </view>
        <view class="f-cell">
          <text class="f-label">热量≤(kcal)</text>
          <input class="f-input" type="digit" v-model="filters.cal" placeholder="如500" />
        </view>
      </view>

      <view class="f-grid" style="margin-top: 12px;">
        <view class="f-cell">
          <text class="f-label">难度≤</text>
          <picker mode="selector" :range="diffNames" :value="diffIdx" @change="(e:any)=>diffIdx=Number(e.detail.value)">
            <view class="f-picker">{{ diffNames[diffIdx] }}</view>
          </picker>
        </view>
        <view class="f-cell">
          <text class="f-label">耗时≤(分)</text>
          <input class="f-input" type="number" v-model="filters.minutes" placeholder="如30" />
        </view>
      </view>

      <view class="f-actions">
        <button class="yh-btn-ghost half sm" @click="resetFilters">重置</button>
        <button class="yh-btn-gradient half sm" @click="reload">应用</button>
      </view>
    </view>

    <!-- 2 列网格卡片 -->
    <view v-if="loading && !dishes.length" class="empty">加载中…</view>
    <view v-else-if="!dishes.length" class="empty">
      <text class="empty-ico">🍳</text>
      <text>还没有自己的菜谱，点 + 录一个吧</text>
    </view>
    <view v-else class="grid">
      <view
        v-for="d in dishes"
        :key="d.id"
        class="dish-card"
        @click="goDetail(d.id)"
      >
        <!-- 封面区 -->
        <view class="cover-wrap">
          <image v-if="d.coverUrl" class="cover" :src="imgUrl(d.coverUrl)" mode="aspectFill" />
          <view v-else class="cover ph-cover">🍽</view>
          <!-- 来源 icon -->
          <view :class="['src-tag', d.source === 'IMPORT' ? 'imp' : 'own']">
            {{ d.source === 'IMPORT' ? '🌐' : '🏠' }}
          </view>
        </view>
        <!-- 信息区 -->
        <view class="d-body">
          <text class="d-name">{{ d.name }}</text>
          <view class="d-meta">
            <text v-if="totalMinutes(d)" class="yh-tag">{{ totalMinutes(d) }}分钟</text>
            <text v-if="d.difficulty" class="yh-tag">难度{{ d.difficulty }}</text>
          </view>
        </view>
      </view>
    </view>
    <view v-if="dishes.length" class="end">
      {{ status === 'nomore' ? '— 没有更多了 —' : status === 'loading' ? '加载中…' : '' }}
    </view>

    <!-- 悬浮 + 按钮 -->
    <view class="fab" @click="onCreate">+</view>
  </view>
</template>

<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { onReachBottom, onPullDownRefresh } from '@dcloudio/uni-app'
import { searchDishes, searchDishesByNutrition } from '@/api/dish'

const dishes = ref<any[]>([])
const keyword = ref('')
const page = ref(1)
const pageSize = 20
const status = ref<'loadmore' | 'loading' | 'nomore'>('loadmore')
const loading = ref(false)

const searchOpen = ref(false)
const showFilter = ref(false)
const activeCat = ref('all')

const cats = [
  { key: 'all', label: '全部' },
  { key: 'done', label: '做过' },
  { key: 'own', label: '自创🏠' },
  { key: 'import', label: '导入🌐' },
  { key: 'star', label: '⭐' },
]

const filters = reactive({ sugar: '', gi: '', cal: '', minutes: '' })
const diffNames = ['不限', '1', '2', '3', '4', '5']
const diffIdx = ref(0)
const METRIC_SUGAR = 5
const METRIC_GI = 6
const METRIC_CAL = 1

const activeFilterCount = computed(() => {
  let n = 0
  if (filters.sugar) n++
  if (filters.gi) n++
  if (filters.cal) n++
  if (filters.minutes) n++
  if (diffIdx.value > 0) n++
  return n
})

function toggleSearch() {
  searchOpen.value = !searchOpen.value
}
function onCat(key: string) {
  activeCat.value = key
  // 当前分类仅做 UI 高亮 + 简单筛选（来源/收藏留 P1 真实接口）
  reload()
}
function clearKeyword() {
  keyword.value = ''
  reload()
}
function goSettings() {
  uni.navigateTo({ url: '/pages/profile/Settings' })
}

function buildParams(pn: number) {
  const p: Record<string, any> = {
    keyword: keyword.value,
    pageNum: pn,
    pageSize,
  }
  if (diffIdx.value > 0) p.maxDifficulty = diffIdx.value
  if (filters.minutes) p.maxMinutes = Number(filters.minutes)
  // 来源分类
  if (activeCat.value === 'own') p.source = 'OWN'
  if (activeCat.value === 'import') p.source = 'IMPORT'
  const limits: Record<string, number> = {}
  if (filters.sugar) limits[METRIC_SUGAR] = Number(filters.sugar)
  if (filters.gi) limits[METRIC_GI] = Number(filters.gi)
  if (filters.cal) limits[METRIC_CAL] = Number(filters.cal)
  if (Object.keys(limits).length) p.nutritionLimits = limits
  return p
}
function resetFilters() {
  filters.sugar = ''
  filters.gi = ''
  filters.cal = ''
  filters.minutes = ''
  diffIdx.value = 0
  reload()
}

async function reload() {
  page.value = 1
  dishes.value = []
  await load()
}
async function load() {
  status.value = 'loading'
  loading.value = true
  try {
    const params = buildParams(page.value)
    const r = params.nutritionLimits
      ? await searchDishesByNutrition(params)
      : await searchDishes(params)
    const records = Array.isArray(r) ? r : (r.records || [])
    // 前端兜底过滤（后端字段名差异，保证 UI 不崩）
    dishes.value.push(...records)
    status.value = records.length < pageSize ? 'nomore' : 'loadmore'
  } catch {
    status.value = 'loadmore'
  } finally {
    loading.value = false
  }
}
function totalMinutes(d: any): number {
  return (Number(d.prepTime) || 0) + (Number(d.cookTime) || 0)
}
function imgUrl(u: string): string {
  if (!u) return ''
  return u.startsWith('http') ? u : '/api' + u
}
function onCreate() {
  uni.showActionSheet({
    itemList: ['手动录入菜谱', '从网页链接导入'],
    success: (r) => {
      if (r.tapIndex === 0) {
        uni.navigateTo({ url: '/pages/dish/Create' })
      } else if (r.tapIndex === 1) {
        uni.navigateTo({ url: '/pages/dish/Create?url=1' })
      }
    },
  })
}
function goDetail(id: number) {
  uni.navigateTo({ url: `/pages/dish/Detail?id=${id}` })
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
</script>

<style scoped>
.page {
  padding: 0 14px 100px;
  min-height: 100vh;
}

/* 顶栏 */
.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: calc(env(safe-area-inset-top) + 16px) 4px 8px;
}
.title-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
}
.title-bar {
  width: 8rpx;
  height: 36rpx;
  background: #FF8C42;
  border-radius: 4rpx;
}
.title {
  font-size: 24px;
  font-weight: bold;
  color: #2D2A26;
}
.top-actions {
  display: flex;
  gap: 12px;
}
.ico-btn {
  font-size: 22px;
  padding: 6px;
}

/* 搜索框 */
.search-box {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #FFFFFF;
  border-radius: 28rpx;
  padding: 12rpx 24rpx;
  margin: 12rpx 0;
  box-shadow: 0 2rpx 8rpx rgba(0, 0, 0, 0.05);
}
.s-ico { font-size: 16px; color: #9B958C; }
.s-input { flex: 1; font-size: 14px; color: #2D2A26; }
.s-ph { color: #B8B2A7; }
.s-clear { font-size: 14px; color: #B8B2A7; padding: 0 4px; }

/* 分类横滑 */
.cat-scroll {
  white-space: nowrap;
  margin: 8rpx 0 4rpx;
}
.cat-row {
  display: inline-flex;
  gap: 12rpx;
  padding: 8rpx 0 12rpx;
}
.cat-chip {
  display: inline-block;
  padding: 10rpx 28rpx;
  border-radius: 30rpx;
  font-size: 26rpx;
  color: #9B958C;
  background: #FFFFFF;
  box-shadow: 0 2rpx 6rpx rgba(0, 0, 0, 0.04);
}
.cat-chip.on {
  background: rgba(255, 140, 66, 0.12);
  color: #FF8C42;
  font-weight: 600;
}

/* 筛选 */
.filter-toggle {
  display: flex; align-items: center; justify-content: center; gap: 6px;
  padding: 6rpx 0 10rpx;
  color: #FF8C42; font-size: 13px;
}
.badge {
  background: #FF8C42; color: #fff; font-size: 11px;
  border-radius: 10px; padding: 0 6px; line-height: 16px;
}
.filter-panel { padding: 14px; }
.f-title { font-size: 12px; color: #9B958C; margin-bottom: 8px; }
.f-grid { display: flex; gap: 8px; }
.f-cell { flex: 1; display: flex; flex-direction: column; gap: 4px; }
.f-label { font-size: 11px; color: #9B958C; }
.f-input {
  background: #FFFBF5; border-radius: 10rpx;
  padding: 10rpx 14rpx; font-size: 13px;
}
.f-picker {
  background: #FFFBF5; border-radius: 10rpx;
  padding: 10rpx 14rpx; font-size: 13px; color: #2D2A26;
}
.f-actions { display: flex; gap: 8px; margin-top: 12px; }
.half { flex: 1; }
.sm { height: 64rpx; line-height: 64rpx; font-size: 13px; padding: 0; }

/* 2 列网格 */
.grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
  padding: 8rpx 0;
}
.dish-card {
  background: #FFFFFF;
  border-radius: 36rpx;
  box-shadow: 0 6rpx 20rpx rgba(0, 0, 0, 0.06);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.cover-wrap {
  position: relative;
  width: 100%;
  height: 220rpx;
}
.cover { width: 100%; height: 100%; }
.ph-cover {
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #FFD9B8, #FFB37A);
  font-size: 56rpx;
  color: rgba(255, 255, 255, 0.8);
}
.src-tag {
  position: absolute;
  top: 12rpx;
  right: 12rpx;
  width: 48rpx;
  height: 48rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24rpx;
  background: rgba(255, 255, 255, 0.85);
}
.d-body {
  padding: 18rpx 22rpx 22rpx;
  display: flex;
  flex-direction: column;
  gap: 10rpx;
}
.d-name {
  font-size: 17px;
  font-weight: bold;
  color: #2D2A26;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}
.d-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 6rpx;
}

/* 空态/底部 */
.empty {
  display: flex; flex-direction: column; align-items: center;
  gap: 12px; padding: 80px 0;
  color: #B8B2A7; font-size: 13px; text-align: center;
}
.empty-ico { font-size: 48px; }
.end { text-align: center; color: #B8B2A7; font-size: 12px; padding: 20rpx 0; }

/* 悬浮 + */
.fab {
  position: fixed;
  right: 36rpx;
  bottom: calc(env(safe-area-inset-bottom) + 140rpx);
  width: 108rpx;
  height: 108rpx;
  border-radius: 54rpx;
  background: linear-gradient(135deg, #FF8C42, #FFA45C);
  color: #FFFFFF;
  font-size: 56rpx;
  font-weight: 300;
  line-height: 108rpx;
  text-align: center;
  box-shadow: 0 8rpx 24rpx rgba(255, 140, 66, 0.4);
  z-index: 99;
}
</style>
