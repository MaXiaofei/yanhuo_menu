<template>
  <view class="page">
    <!-- 顶栏 -->
    <view class="topbar">
      <text class="back" @click="goBack">‹</text>
      <text class="top-title">今日</text>
      <view class="back"></view>
    </view>

    <!-- 问候区 -->
    <view class="greeting">
      <text class="hi">{{ greeting }}，{{ memberName }} 👋</text>
      <text class="quote">{{ todayQuote }}</text>
    </view>

    <!-- 金句横滑轮播 -->
    <scroll-view scroll-x class="quote-scroll" :show-scrollbar="false">
      <view class="quote-row">
        <view
          v-for="(q, i) in quotes"
          :key="i"
          :class="['quote-card', q.includes('烟火') ? 'hot' : '']"
        >
          <text class="q-mark">"</text>
          <text class="q-text">{{ q }}</text>
          <text class="q-mark-end">"</text>
        </view>
      </view>
    </scroll-view>

    <!-- 今日推荐卡（渐变底） -->
    <view class="recommend-card" @click="onRecommend">
      <view class="rec-head">
        <text class="rec-flame">🔥</text>
        <text class="rec-label">今日推荐</text>
      </view>
      <text class="rec-title">今天给全家做点啥？</text>
      <text class="rec-sub">{{ recommending ? 'AI 想菜中…' : '打开 AI 帮你换换灵感 →' }}</text>
    </view>

    <!-- 功能宫格 -->
    <view class="block-title">
      <view class="tbar"></view>
      <text>常用功能</text>
    </view>
    <view class="grid">
      <view class="grid-cell" @click="go('/pages/dish/List')">
        <view class="cell-ico" style="background: rgba(255,159,90,0.15); color:#FF9F5A;">📖</view>
        <text class="cell-name">菜库</text>
      </view>
      <view class="grid-cell" @click="go('/pages/pantry/List')">
        <view class="cell-ico" style="background: rgba(111,191,142,0.15); color:#6FBF8E;">🧊</view>
        <text class="cell-name">食材库存</text>
      </view>
      <view class="grid-cell" @click="go('/pages/mealplan/Calendar')">
        <view class="cell-ico" style="background: rgba(107,168,232,0.15); color:#6BA8E8;">📅</view>
        <text class="cell-name">周计划</text>
      </view>
      <view class="grid-cell" @click="go('/pages/shopping/List')">
        <view class="cell-ico" style="background: rgba(232,163,61,0.15); color:#E8A33D;">🛒</view>
        <text class="cell-name">采购清单</text>
      </view>
      <view class="grid-cell" @click="go('/pages/dailylog/Index')">
        <view class="cell-ico" style="background: rgba(176,123,216,0.15); color:#B07BD8;">📝</view>
        <text class="cell-name">饮食记录</text>
      </view>
      <view class="grid-cell" @click="go('/pages/ai/Recommend')">
        <view class="cell-ico" style="background: rgba(224,123,123,0.15); color:#E07B7B;">✨</view>
        <text class="cell-name">AI 帮我</text>
      </view>
    </view>

    <view style="height: 60rpx;"></view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { useMemberStore } from '@/store/member'
import { aiRecommendMenu } from '@/api/ai'

const m = useMemberStore()
const memberName = computed(() => {
  const cur = m.members.find((x: any) => x.id === m.currentId)
  return cur?.name || '掌勺人'
})
const recommending = ref(false)

const greeting = computed(() => {
  const h = new Date().getHours()
  if (h < 6) return '夜深了'
  if (h < 11) return '早安'
  if (h < 14) return '午安'
  if (h < 18) return '下午好'
  return '晚上好'
})

const quotes = [
  '一日三餐，是家人之间最朴素的约定',
  '厨房里的烟火，是生活最真实的模样',
  '每一道菜，都藏着对家人的爱',
  '做饭不难，难的是日复一日的坚持',
  '最好的味道，永远是家的味道',
  '厨房是家的心脏，锅碗瓢盆是它的心跳',
  '把爱揉进面团，把暖熬进汤里',
  '一家人围着桌子，就是最好的时光',
  '今天吃什么，是全世界最难的问题',
  '冰箱里的食材，是明天早餐的开始',
  '火候到了，味道自然就来了',
  '调味的手感，是无数次尝试后的本能',
  '剩下的饭菜，明天热一热还是家的味道',
  '掌勺的人，是家里最温柔的英雄',
]
const todayQuote = computed(() => {
  const day = Math.floor((Date.now() - new Date(2026, 0, 1).getTime()) / 86400000)
  return quotes[((day % quotes.length) + quotes.length) % quotes.length]
})

function go(url: string) {
  uni.navigateTo({ url, fail: () => uni.switchTab({ url }) })
}
function goBack() {
  uni.navigateBack({ fail: () => uni.switchTab({ url: '/pages/misc/Home' }) })
}

async function onRecommend() {
  if (recommending.value) return
  recommending.value = true
  try {
    const groups = await aiRecommendMenu({ scope: 'DAY' })
    if (groups && groups.length) {
      const first = groups[0]
      const names = (first.dishes || []).map((d: any) => d.name).join('、')
      uni.showModal({
        title: '今晚吃这些？',
        content: names || '暂无推荐',
        confirmText: '看看菜谱',
        cancelText: '换一个',
        success: (r) => {
          if (r.confirm && first.dishes && first.dishes[0]) {
            uni.navigateTo({ url: `/pages/dish/Detail?id=${first.dishes[0].dishId}` })
          }
        },
      })
    } else {
      uni.showToast({ title: '暂无推荐', icon: 'none' })
    }
  } catch (e: any) {
    uni.showToast({ title: e?.message || '推荐失败', icon: 'none' })
  } finally {
    recommending.value = false
  }
}

onShow(() => { m.load() })
</script>

<style scoped>
.page {
  padding: 0 28rpx calc(env(safe-area-inset-bottom) + 40rpx);
  min-height: 100vh;
}

/* 顶栏 */
.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: calc(env(safe-area-inset-top) + 24rpx) 12rpx 8rpx;
}
.back {
  width: 60rpx;
  font-size: 48rpx;
  color: #2D2A26;
  text-align: center;
}
.top-title {
  font-size: 32rpx;
  font-weight: 600;
  color: #2D2A26;
}

/* 问候 */
.greeting {
  padding: 32rpx 12rpx 12rpx;
}
.hi {
  display: block;
  font-size: 44rpx;
  font-weight: bold;
  color: #2D2A26;
}
.quote {
  display: block;
  margin-top: 12rpx;
  font-size: 26rpx;
  font-style: italic;
  color: #C4A882;
}

/* 金句轮播 */
.quote-scroll {
  white-space: nowrap;
  margin: 24rpx 0;
}
.quote-row {
  display: inline-flex;
  gap: 20rpx;
  padding: 8rpx 0;
}
.quote-card {
  display: inline-flex;
  flex-direction: column;
  align-items: center;
  width: 360rpx;
  padding: 36rpx 28rpx;
  background: #FFFFFF;
  border-radius: 28rpx;
  box-shadow: 0 4rpx 14rpx rgba(0, 0, 0, 0.06);
  white-space: normal;
  text-align: center;
}
.quote-card.hot {
  background: linear-gradient(135deg, #FF8C42, #FFA45C);
}
.q-mark {
  font-size: 56rpx;
  color: #FF8C42;
  line-height: 0.8;
}
.q-mark-end {
  font-size: 56rpx;
  color: #FF8C42;
  line-height: 0.4;
  align-self: flex-end;
}
.hot .q-mark, .hot .q-mark-end { color: rgba(255,255,255,0.6); }
.q-text {
  font-size: 28rpx;
  line-height: 1.6;
  color: #2D2A26;
  margin: 8rpx 0;
}
.hot .q-text { color: #FFFFFF; font-weight: 600; }

/* 今日推荐卡 */
.recommend-card {
  margin-top: 24rpx;
  background: linear-gradient(135deg, #FF8C42, #E6762A);
  border-radius: 36rpx;
  padding: 40rpx;
  display: flex;
  flex-direction: column;
  gap: 8rpx;
  box-shadow: 0 8rpx 24rpx rgba(255, 140, 66, 0.3);
}
.rec-head {
  display: flex;
  align-items: center;
  gap: 8rpx;
}
.rec-flame { font-size: 28rpx; }
.rec-label {
  font-size: 24rpx;
  color: rgba(255, 255, 255, 0.9);
}
.rec-title {
  font-size: 40rpx;
  font-weight: bold;
  color: #FFFFFF;
}
.rec-sub {
  font-size: 26rpx;
  color: rgba(255, 255, 255, 0.92);
}

/* 宫格标题 */
.block-title {
  display: flex;
  align-items: center;
  gap: 12rpx;
  margin: 48rpx 12rpx 24rpx;
}
.tbar {
  width: 8rpx;
  height: 32rpx;
  background: #FF8C42;
  border-radius: 4rpx;
}
.block-title text {
  font-size: 32rpx;
  font-weight: bold;
  color: #2D2A26;
}

/* 宫格 */
.grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 20rpx;
}
.grid-cell {
  background: #FFFFFF;
  border-radius: 28rpx;
  box-shadow: 0 4rpx 14rpx rgba(0, 0, 0, 0.05);
  padding: 28rpx 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12rpx;
}
.cell-ico {
  width: 88rpx;
  height: 88rpx;
  border-radius: 28rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 44rpx;
}
.cell-name {
  font-size: 26rpx;
  color: #2D2A26;
  font-weight: 500;
}
</style>
