<template>
  <view class="shopping">
    <!-- 顶部：选择周计划生成 -->
    <view class="gen-bar">
      <view class="gen-label">从周计划生成：</view>
      <view class="gen-input" @click="showPlanPicker = true">
        {{ currentPlan ? (currentPlan.name || weekText(currentPlan.weekStart)) : '选择周计划' }}
      </view>
      <view class="gen-btn" :class="{ disabled: !currentPlan || generating }" @click="onGenerate">
        {{ generating ? '生成中…' : '生成清单' }}
      </view>
    </view>

    <!-- 生成出的清单详情 -->
    <view v-if="loading" class="empty">加载中…</view>
    <view v-else-if="!detail" class="empty">暂无采购清单（请先生成）</view>
    <view v-else class="detail">
      <view class="detail-head">
        <text class="title">采购清单</text>
        <text class="range">{{ rangeText(detail) }}</text>
      </view>

      <view v-if="!detail.items || !detail.items.length" class="empty">该清单暂无采购项</view>

      <!-- 按品类分区展示 -->
      <view v-for="(items, catKey) in detail.grouped" :key="catKey" class="category">
        <view class="cat-title">{{ categoryName(catKey) }}</view>
        <view v-for="it in items" :key="it.id" :class="['item', it.purchased === 1 && 'done']">
          <view class="check" @click="onToggle(it)">
            <view :class="['box', it.purchased === 1 && 'checked']">✓</view>
          </view>
          <text class="iname">{{ it.ingredientName || '#' + it.ingredientId }}</text>
          <text class="iamt">{{ it.totalAmount }} {{ it.unitName || '' }}</text>
        </view>
      </view>
    </view>

    <!-- 周计划选择 -->
    <u-picker :show="showPlanPicker" :columns="[planNames]" @confirm="onPickPlan" @cancel="showPlanPicker = false" />
  </view>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import {
  generate,
  getDetail,
  togglePurchased,
  listShopping,
  type ShoppingListVO,
  type ShoppingItemVO,
  type ShoppingList
} from '@/api/shopping'
import { request } from '@/utils/request'

// 周计划（轻量列表：id + weekStart + name）
interface PlanLite { id: number; weekStart: string; name?: string }

const plans = ref<PlanLite[]>([])
const currentPlan = ref<PlanLite | null>(null)
const showPlanPicker = ref(false)
const detail = ref<ShoppingListVO | null>(null)
const loading = ref(false)
const generating = ref(false)

const planNames = computed(() =>
  plans.value.map(p => p.name || weekText(p.weekStart))
)

function weekText(weekStart?: string): string {
  if (!weekStart) return '#'
  return weekStart + ' 起'
}
function rangeText(d: ShoppingListVO): string {
  if (d.startDate && d.endDate) return `${d.startDate} ~ ${d.endDate}`
  return d.timeRange || ''
}
function categoryName(catKey: string | number): string {
  const names = detail.value?.categoryNames
  if (names && names[String(catKey)]) return names[String(catKey)]
  // 未带中文名的分区（含 null）
  return catKey === 'null' || catKey == null ? '其他' : `品类#${catKey}`
}

async function loadPlans() {
  try {
    const records = await listShopping()
    // 复用 /mealplan 列表拿周计划（小程序按需）
    const mealPlans = await request<{ records: PlanLite[]; total: number }>({
      url: '/mealplan',
      method: 'GET',
      data: { pageNum: 1, pageSize: 100 }
    }).then((p: any) => p.records || [])
    plans.value = mealPlans
    // 最近一张采购清单默认展示
    if (records.length && !detail.value) {
      await loadDetail(records[0].id)
    }
  } catch {
    /* 静默 */
  }
}

async function loadDetail(listId: number) {
  loading.value = true
  try {
    detail.value = await getDetail(listId)
  } finally {
    loading.value = false
  }
}

function onPickPlan(e: any) {
  const idx = e.indexs ? e.indexs[0] : e.index[0]
  currentPlan.value = plans.value[idx] || null
  showPlanPicker.value = false
}

async function onGenerate() {
  if (!currentPlan.value || generating.value) return
  generating.value = true
  try {
    const listId = await generate(currentPlan.value.id, 'week')
    uni.showToast({ title: '生成成功', icon: 'success' })
    await loadDetail(listId)
  } catch (e: any) {
    uni.showToast({ title: e?.msg || '生成失败', icon: 'none' })
  } finally {
    generating.value = false
  }
}

async function onToggle(it: ShoppingItemVO) {
  try {
    await togglePurchased(it.id)
    it.purchased = it.purchased === 1 ? 0 : 1
  } catch (e: any) {
    uni.showToast({ title: e?.msg || '操作失败', icon: 'none' })
  }
}

onShow(() => { loadPlans() })
</script>

<style scoped>
.shopping { padding: 12px; }
.gen-bar { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; background: #fff; padding: 10px; border-radius: 8px; }
.gen-label { font-size: 13px; color: #666; white-space: nowrap; }
.gen-input { flex: 1; font-size: 14px; color: #333; border: 1px solid #eee; border-radius: 6px; padding: 6px 8px; }
.gen-btn { font-size: 13px; color: #fff; background: #FF8C42; padding: 7px 12px; border-radius: 6px; white-space: nowrap; }
.gen-btn.disabled { background: #ccc; }
.empty { text-align: center; color: #aaa; padding: 40px 0; font-size: 13px; }
.detail { display: flex; flex-direction: column; gap: 12px; }
.detail-head { display: flex; justify-content: space-between; align-items: baseline; }
.title { font-size: 16px; font-weight: 700; color: #333; }
.range { font-size: 12px; color: #999; }
.category { background: #fff; border-radius: 8px; padding: 10px 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
.cat-title { font-size: 13px; font-weight: 600; color: #FF8C42; padding-bottom: 6px; border-bottom: 1px dashed #f0e0d0; margin-bottom: 6px; }
.item { display: flex; align-items: center; padding: 8px 0; border-bottom: 1px solid #f5f5f5; }
.item:last-child { border-bottom: none; }
.item.done .iname { color: #bbb; text-decoration: line-through; }
.item.done .iamt { color: #ccc; }
.check { padding: 0 10px 0 0; }
.box { width: 20px; height: 20px; border: 2px solid #ddd; border-radius: 4px; display: flex; align-items: center; justify-content: center; font-size: 13px; color: transparent; }
.box.checked { background: #FF8C42; border-color: #FF8C42; color: #fff; }
.iname { flex: 1; font-size: 15px; color: #333; }
.iamt { font-size: 14px; color: #FF8C42; font-weight: 600; }
</style>
