<template>
  <view class="detail" v-if="dish">
    <u-image :src="imgUrl(dish.coverUrl)" width="100%" height="200" v-if="dish.coverUrl" />
    <view class="info">
      <text class="title">{{ dish.name }}</text>
      <text class="meta">备料 {{ dish.prepTime || 0 }}分 · 烹饪 {{ dish.cookTime || 0 }}分 · 难度 {{ dish.difficulty || '-' }}/5</text>
      <text class="note" v-if="dish.note">{{ dish.note }}</text>
    </view>
    <view class="nutrition" v-if="nutritionDisplay.length">
      <text class="section">营养（份数 {{ serving }}）</text>
      <view class="tags">
        <u-tag v-for="(n, i) in nutritionDisplay" :key="i" :text="`${n.label}: ${n.value}`" type="success" size="mini" />
      </view>
    </view>
    <view class="steps">
      <text class="section">做法</text>
      <view class="step" v-for="(s, i) in steps" :key="i">
        <view class="step-head">
          <text>步骤 {{ i + 1 }}</text>
          <u-button size="mini" :type="active === i ? 'error' : 'primary'" @click="toggleTimer(i)">
            {{ active === i ? '停止' : '计时' }}
          </u-button>
        </view>
        <text class="step-text">{{ s.text }}</text>
        <view class="step-imgs" v-if="imgs(s.images).length">
          <u-image v-for="(img, j) in imgs(s.images)" :key="j" :src="imgUrl(img)" width="80" height="80" />
        </view>
        <view class="timer" v-if="active === i">⏱ {{ elapsed }}s</view>
      </view>
    </view>
    <view class="actions">
      <u-button type="warning" @click="onMarkDone">标记做过</u-button>
      <u-button @click="goReview">去点评</u-button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onUnmounted } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { dishDetail, dishNutrition, markDone, nutritionMetrics } from '@/api/dish'
import { useMemberStore } from '@/store/member'

const m = useMemberStore()
// detail 返回 { dish, steps, cuisineIds, tagIds, categoryIds, ingredients }
const data = ref<any>(null)
const dish = computed(() => data.value?.dish || null)
const steps = computed(() => data.value?.steps || [])

const nutrition = ref<Record<string, any>>({})
const metrics = ref<any[]>([])
const serving = ref(1)
const dishId = ref(0)
const active = ref(-1)
const elapsed = ref(0)
let timer: any = null

// 后端 nutrition_metric 字典的 name 是英文（calorie/protein/fat/carb/sugar/gi），家庭看不懂 → 中文映射，兜底英文防新增指标无映射
const METRIC_CN: Record<string, string> = {
  calorie: '热量',
  protein: '蛋白质',
  fat: '脂肪',
  carb: '碳水',
  sugar: '糖',
  gi: '升糖指数'
}

// 把 nutrition(Map 指标id→值) + metrics(字典) 合成可读列表「名字: 值(单位)」
const nutritionDisplay = computed(() => {
  const arr: { label: string; value: any }[] = []
  for (const m of metrics.value) {
    const v = nutrition.value[m.id]
    if (v !== undefined && v !== null) arr.push({ label: METRIC_CN[m.name] || m.name, value: `${v}${m.unit ? m.unit : ''}` })
  }
  return arr
})

onLoad(async (q: any) => {
  dishId.value = q.id
  try {
    data.value = await dishDetail(q.id)
  } catch {
    uni.showToast({ title: '加载详情失败', icon: 'none' })
    return
  }
  try {
    nutrition.value = await dishNutrition(q.id, serving.value)
  } catch {
    // 营养加载失败不阻断详情展示
  }
  try {
    metrics.value = await nutritionMetrics()
  } catch {
    // 字典加载失败不阻断详情展示
  }
})

function toggleTimer(i: number) {
  if (active.value === i && timer) {
    clearInterval(timer)
    timer = null
    active.value = -1
    return
  }
  if (timer) clearInterval(timer)
  active.value = i
  elapsed.value = 0
  timer = setInterval(() => { elapsed.value++ }, 1000)
}
onUnmounted(() => { if (timer) clearInterval(timer) })

function imgs(s: any): string[] {
  return s ? String(s).split(',').filter(Boolean) : []
}
function imgUrl(u: string): string {
  if (!u) return ''
  return u.startsWith('http') ? u : '/api' + u
}
async function onMarkDone() {
  if (!m.currentId) {
    uni.showToast({ title: '请先选择就餐成员', icon: 'none' })
    return
  }
  try {
    await markDone(dishId.value, m.currentId)
    uni.showToast({ title: '已记录' })
  } catch {
    // request.ts 已弹 toast
  }
}
function goReview() {
  uni.navigateTo({ url: `/pages/dish/Review?dishId=${dishId.value}`, fail: () => uni.showToast({ title: '点评页未就绪', icon: 'none' }) })
}
</script>

<style scoped>
.detail { padding-bottom: 40rpx; }
.info { padding: 20rpx; }
.title { font-size: 36rpx; font-weight: bold; display: block; }
.meta { font-size: 24rpx; color: #999; display: block; margin-top: 8rpx; }
.note { font-size: 24rpx; color: #666; display: block; margin-top: 8rpx; }
.section { font-size: 30rpx; font-weight: bold; padding: 20rpx; display: block; }
.nutrition .tags { padding: 0 20rpx 10rpx; }
.step { padding: 16rpx 20rpx; border-top: 1rpx solid #eee; }
.step-head { display: flex; justify-content: space-between; align-items: center; }
.step-text { display: block; margin: 12rpx 0; font-size: 28rpx; }
.step-imgs { display: flex; flex-wrap: wrap; gap: 12rpx; }
.timer { color: #FF8C42; font-size: 32rpx; font-weight: bold; margin-top: 12rpx; }
.actions { padding: 30rpx 20rpx; display: flex; flex-direction: column; gap: 20rpx; }
</style>
