<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  listShopping,
  getShoppingDetail,
  generateShopping,
  togglePurchased,
  deleteShoppingItem,
  deleteShoppingList,
  type ShoppingList,
  type ShoppingListVO,
  type ShoppingItemVO,
} from '@/api/shopping'
import { listPlans, type MealPlan } from '@/api/mealplan'

// ============ 清单分页列表 ============
const loading = ref(false)
const list = ref<ShoppingList[]>([])
const total = ref(0)
const pageNum = ref(1)
const pageSize = 10

async function load() {
  loading.value = true
  try {
    const page = await listShopping({ pageNum: pageNum.value, pageSize })
    list.value = page.records || []
    total.value = page.total || 0
  } finally {
    loading.value = false
  }
}

function onPageChange(p: number) {
  pageNum.value = p
  load()
}

// ============ 从周计划生成 ============
const plans = ref<MealPlan[]>([])
const genDialogVisible = ref(false)
const genForm = reactive({ planId: undefined as unknown as number, timeRange: 'week' })
const generating = ref(false)

function openGenerate() {
  genForm.planId = undefined as unknown as number
  genForm.timeRange = 'week'
  genDialogVisible.value = true
}

async function onGenerate() {
  if (!genForm.planId) {
    ElMessage.warning('请选择周计划')
    return
  }
  generating.value = true
  try {
    const listId = await generateShopping(genForm.planId, genForm.timeRange)
    ElMessage.success(`已生成采购清单 #${listId}`)
    genDialogVisible.value = false
    pageNum.value = 1
    await load()
    await openDetail(listId)
  } finally {
    generating.value = false
  }
}

// ============ 清单详情（按品类分区 + 勾选已买） ============
const detailVisible = ref(false)
const detail = ref<ShoppingListVO | null>(null)
const detailLoading = ref(false)

async function openDetail(listId: number) {
  detailVisible.value = true
  detailLoading.value = true
  try {
    detail.value = await getShoppingDetail(listId)
  } finally {
    detailLoading.value = false
  }
}

// 分区视图：把 grouped（key 是字符串/数字，含 null）转成有序数组
function categoryGroups() {
  const g = detail.value?.grouped
  if (!g) return []
  return Object.entries(g).map(([k, items]) => ({
    catKey: k,
    catName: categoryName(k),
    items: items || [],
  }))
}

function categoryName(catKey: string): string {
  const names = detail.value?.categoryNames
  if (names && names[String(catKey)]) return String(names[String(catKey)])
  if (catKey === 'null' || catKey === 'undefined' || catKey == null) return '其他'
  return `品类#${catKey}`
}

async function onToggle(row: ShoppingItemVO) {
  try {
    await togglePurchased(row.id)
    row.purchased = row.purchased === 1 ? 0 : 1
  } catch {
    ElMessage.error('操作失败')
  }
}

async function onDeleteItem(row: ShoppingItemVO) {
  await ElMessageBox.confirm(`确定删除「${row.ingredientName || '该项'}」？`, '提示', { type: 'warning' })
  await deleteShoppingItem(row.id)
  ElMessage.success('已删除')
  if (detail.value) await openDetail(detail.value.id)
}

async function onDeleteList(row: ShoppingList) {
  await ElMessageBox.confirm(`确定删除采购清单 #${row.id}？`, '提示', { type: 'warning' })
  await deleteShoppingList(row.id)
  ElMessage.success('已删除')
  await load()
}

function rangeText(row: ShoppingList): string {
  if (row.startDate && row.endDate) return `${row.startDate} ~ ${row.endDate}`
  return row.timeRange || '-'
}

function countText(row: ShoppingList): string {
  // 列表行无 items，只显示元信息
  return row.sourcePlanId ? `来自周计划 #${row.sourcePlanId}` : '手工'
}

onMounted(async () => {
  await load()
  try {
    const p = await listPlans({ pageNum: 1, pageSize: 100 })
    plans.value = p.records || []
  } catch {
    /* 静默 */
  }
})
</script>

<template>
  <div class="page">
    <div class="toolbar">
      <el-button type="primary" @click="openGenerate">从周计划生成</el-button>
    </div>

    <el-table v-loading="loading" :data="list" border>
      <el-table-column label="清单号" prop="id" width="100" />
      <el-table-column label="来源" min-width="160">
        <template #default="{ row }">
          <span>{{ countText(row) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="时间范围" min-width="180">
        <template #default="{ row }">
          <span class="mini">{{ rangeText(row) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="生成时间" width="180">
        <template #default="{ row }">
          <span class="mini">{{ row.createdAt || row.timeRange || '-' }}</span>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="220" fixed="right">
        <template #default="{ row }">
          <el-button link type="primary" @click="openDetail(row.id)">查看明细</el-button>
          <el-button link type="danger" @click="onDeleteList(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination
      background
      layout="total, prev, pager, next, jumper"
      :total="total"
      :page-size="pageSize"
      :current-page="pageNum"
      @current-change="onPageChange"
      style="margin-top: 16px; justify-content: flex-end; display: flex"
    />

    <!-- 从周计划生成 -->
    <el-dialog v-model="genDialogVisible" title="从周计划生成采购清单" width="480px">
      <el-form label-width="90px">
        <el-form-item label="周计划">
          <el-select v-model="genForm.planId" filterable placeholder="选择周计划" style="width: 100%">
            <el-option
              v-for="p in plans"
              :key="p.id"
              :label="p.name || `${p.weekStart} 起`"
              :value="p.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-select v-model="genForm.timeRange" style="width: 100%">
            <el-option label="一周" value="week" />
            <el-option label="单日" value="day" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="genDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="generating" @click="onGenerate">生成</el-button>
      </template>
    </el-dialog>

    <!-- 清单详情：按品类分区 + 勾选已买 -->
    <el-dialog v-model="detailVisible" title="采购清单明细" width="640px">
      <div v-loading="detailLoading">
        <div v-if="!detail || !detail.items || !detail.items.length" class="empty">
          该清单暂无采购项
        </div>
        <div v-else>
          <div class="detail-head">
            <span>共 {{ detail.items.length }} 项</span>
            <span class="mini">{{ rangeText(detail) }}</span>
          </div>
          <div v-for="g in categoryGroups()" :key="g.catKey" class="cat-block">
            <div class="cat-title">{{ g.catName }}（{{ g.items.length }}）</div>
            <div v-for="it in g.items" :key="it.id" :class="['item-row', it.purchased === 1 && 'done']">
              <el-checkbox
                :model-value="it.purchased === 1"
                @change="onToggle(it)"
              >
                <span class="iname">{{ it.ingredientName || `#${it.ingredientId}` }}</span>
              </el-checkbox>
              <span class="iamt">{{ it.totalAmount }} {{ it.unitName || '' }}</span>
              <el-button link type="danger" size="small" @click="onDeleteItem(it)">删除</el-button>
            </div>
          </div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<style scoped>
.page {
  background: var(--yh-panel, #fff);
  padding: 16px;
  border-radius: 8px;
}
.toolbar {
  margin-bottom: 12px;
}
.mini {
  font-size: 12px;
  color: #7a6f60;
}
.empty {
  text-align: center;
  color: #aaa;
  padding: 30px 0;
  font-size: 13px;
}
.detail-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 12px;
  font-size: 14px;
  color: #555;
}
.cat-block {
  margin-bottom: 14px;
  border: 1px solid #f0e0d0;
  border-radius: 6px;
  padding: 8px 12px;
}
.cat-title {
  font-size: 14px;
  font-weight: 600;
  color: #ff8c42;
  border-bottom: 1px dashed #f0e0d0;
  padding-bottom: 6px;
  margin-bottom: 4px;
}
.item-row {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 0;
  border-bottom: 1px solid #f5f5f5;
}
.item-row:last-child {
  border-bottom: none;
}
.item-row.done .iname {
  color: #bbb;
  text-decoration: line-through;
}
.iname {
  flex: 1;
}
.iamt {
  font-size: 14px;
  color: #ff8c42;
  font-weight: 600;
  min-width: 80px;
  text-align: right;
}
</style>
