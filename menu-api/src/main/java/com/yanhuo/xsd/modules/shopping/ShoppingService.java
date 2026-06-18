package com.yanhuo.xsd.modules.shopping;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.yanhuo.xsd.common.PageQuery;
import com.yanhuo.xsd.modules.dict.SysDict;
import com.yanhuo.xsd.modules.dict.mapper.DictMapper;
import com.yanhuo.xsd.modules.dish.DishIngredient;
import com.yanhuo.xsd.modules.dish.mapper.DishIngredientMapper;
import com.yanhuo.xsd.modules.mealplan.MealPlan;
import com.yanhuo.xsd.modules.mealplan.MealPlanItem;
import com.yanhuo.xsd.modules.mealplan.mapper.MealPlanItemMapper;
import com.yanhuo.xsd.modules.mealplan.mapper.MealPlanMapper;
import com.yanhuo.xsd.modules.nutrition.Ingredient;
import com.yanhuo.xsd.modules.nutrition.mapper.IngredientMapper;
import com.yanhuo.xsd.modules.shopping.ShoppingAggregator.Usage;
import com.yanhuo.xsd.modules.shopping.mapper.ShoppingItemMapper;
import com.yanhuo.xsd.modules.shopping.mapper.ShoppingListMapper;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 采购清单服务。
 *
 * <p>核心流程 generateFromPlan：
 * 查 meal_plan_item 的 dish_id 列表 → 查各 dish 的 dish_ingredient(用量)
 * → join ingredient 拿 unit_id/purchase_category_id → 组装 Usage →
 * aggregator.aggregate → 落 shopping_list + shopping_item。
 *
 * <p>不做估价（price 无意义）。VO 带中文（食材名/单位名/品类名，枚举铁律）。
 *
 * <p>参照 MealPlanService / PantryService 范式：ServiceImpl 主表 + 显式多 Mapper 构造。
 */
@Service
public class ShoppingService extends ServiceImpl<ShoppingListMapper, ShoppingList> {

    private final ShoppingItemMapper itemMapper;
    private final MealPlanItemMapper mealPlanItemMapper;
    private final MealPlanMapper mealPlanMapper;
    private final DishIngredientMapper dishIngredientMapper;
    private final IngredientMapper ingredientMapper;
    private final DictMapper dictMapper;
    private final ShoppingAggregator aggregator;

    @Autowired
    public ShoppingService(ShoppingItemMapper itemMapper,
                           MealPlanItemMapper mealPlanItemMapper,
                           MealPlanMapper mealPlanMapper,
                           DishIngredientMapper dishIngredientMapper,
                           IngredientMapper ingredientMapper,
                           DictMapper dictMapper,
                           ShoppingAggregator aggregator) {
        this.itemMapper = itemMapper;
        this.mealPlanItemMapper = mealPlanItemMapper;
        this.mealPlanMapper = mealPlanMapper;
        this.dishIngredientMapper = dishIngredientMapper;
        this.ingredientMapper = ingredientMapper;
        this.dictMapper = dictMapper;
        this.aggregator = aggregator;
    }

    // ===================== 生成 =====================

    /**
     * 从周计划生成采购清单：聚合该计划下所有菜的食材用量，合并同食材(同单位)，落库。
     *
     * <p>合并契约由 {@link ShoppingAggregator} 保证：同 (ingredient, unit) 相加；不同单位分开。
     * servingFactor 纳入用量缩放（默认 1）。
     *
     * @param planId    周计划 id
     * @param timeRange 时间范围标识（如 week / day），仅记录用
     * @return 新生成的 shopping_list.id
     */
    @Transactional
    public Long generateFromPlan(Long planId, String timeRange) {
        // 1. 取该计划所有排菜项
        List<MealPlanItem> planItems = mealPlanItemMapper.selectList(
                new QueryWrapper<MealPlanItem>().eq("plan_id", planId));
        if (planItems.isEmpty()) {
            // 空计划也建一条空清单，便于前端展示「无采购项」
            return persistEmptyPlan(planId, timeRange);
        }

        // 2. 收集 dish_id → 各菜用量
        List<Long> dishIds = planItems.stream().map(MealPlanItem::getDishId).distinct().collect(Collectors.toList());
        List<DishIngredient> dis = dishIngredientMapper.selectList(
                new QueryWrapper<DishIngredient>().in("dish_id", dishIds));
        if (dis.isEmpty()) {
            return persistEmptyPlan(planId, timeRange);
        }

        // 3. dish_id → servingFactor（同菜按其排菜项的份数系数之和近似；为简化取首项）
        Map<Long, BigDecimal> factorByDish = new HashMap<>();
        for (MealPlanItem pi : planItems) {
            BigDecimal f = pi.getServingFactor() == null ? BigDecimal.ONE : pi.getServingFactor();
            factorByDish.merge(pi.getDishId(), f, BigDecimal::add);
        }

        // 4. ingredient_id → ingredient（拿 unit/purchase_category）
        List<Long> ingIds = dis.stream().map(DishIngredient::getIngredientId).distinct().collect(Collectors.toList());
        Map<Long, Ingredient> ingById = ingredientMapper.selectList(
                new QueryWrapper<Ingredient>().in("id", ingIds)).stream()
                .collect(Collectors.toMap(Ingredient::getId, i -> i, (a, b) -> a));

        // 5. 组装 Usage 列表（用量 × 份数系数）
        List<Usage> usages = new ArrayList<>();
        for (DishIngredient di : dis) {
            Ingredient ing = ingById.get(di.getIngredientId());
            if (ing == null) continue;
            BigDecimal factor = factorByDish.getOrDefault(di.getDishId(), BigDecimal.ONE);
            BigDecimal amount = di.getAmount() == null ? BigDecimal.ZERO : di.getAmount();
            BigDecimal scaled = amount.multiply(factor);
            usages.add(new Usage(ing.getId(), ing.getUnitId(), scaled, ing.getPurchaseCategoryId()));
        }

        // 6. 合并
        List<ShoppingAggregator.ShoppingLine> lines = aggregator.aggregate(usages);

        // 7. 落库：先建 list，再批量插 item
        ShoppingList list = newList(planId, timeRange);
        save(list);
        for (ShoppingAggregator.ShoppingLine l : lines) {
            ShoppingItem item = new ShoppingItem();
            item.setListId(list.getId());
            item.setIngredientId(l.ingredientId());
            item.setTotalAmount(l.totalAmount());
            item.setUnitId(l.unitId());
            item.setPurchaseCategoryId(l.purchaseCategoryId());
            item.setPurchased(0);
            itemMapper.insert(item);
        }
        return list.getId();
    }

    private Long persistEmptyPlan(Long planId, String timeRange) {
        ShoppingList list = newList(planId, timeRange);
        save(list);
        return list.getId();
    }

    private ShoppingList newList(Long planId, String timeRange) {
        ShoppingList list = new ShoppingList();
        list.setSourcePlanId(planId);
        list.setTimeRange(timeRange);
        MealPlan plan = planId == null ? null : mealPlanMapper.selectById(planId);
        if (plan != null && plan.getWeekStart() != null) {
            list.setStartDate(plan.getWeekStart());
            list.setEndDate(plan.getWeekStart().plusDays(6));
        } else {
            list.setStartDate(LocalDate.now());
            list.setEndDate(LocalDate.now().plusDays(6));
        }
        return list;
    }

    // ===================== 查询 =====================

    /** 采购清单详情：含 items（带中文）+ 按品类分区视图。 */
    public ShoppingListVO getDetail(Long listId) {
        ShoppingList list = getById(listId);
        List<ShoppingItem> rows = itemMapper.selectList(
                new QueryWrapper<ShoppingItem>().eq("list_id", listId)
                        .orderByAsc("purchase_category_id").orderByAsc("ingredient_id"));
        List<ShoppingItemVO> items = fillVoNames(rows);
        ShoppingListVO vo = new ShoppingListVO();
        BeanUtils.copyProperties(list, vo);
        vo.setItems(items);
        // 分区视图
        Map<Long, List<ShoppingItemVO>> grouped = new LinkedHashMap<>();
        Map<Long, String> catNames = new LinkedHashMap<>();
        for (ShoppingItemVO it : items) {
            grouped.computeIfAbsent(it.getPurchaseCategoryId(), k -> new ArrayList<>()).add(it);
            if (it.getPurchaseCategoryId() != null) {
                catNames.putIfAbsent(it.getPurchaseCategoryId(), it.getPurchaseCategoryName());
            }
        }
        vo.setGrouped(grouped);
        vo.setCategoryNames(catNames);
        return vo;
    }

    /** 分页查采购清单（后台管理，不含 items，按创建时间倒序）。 */
    public IPage<ShoppingList> page(PageQuery q) {
        return page(new Page<>(q.getPageNum(), q.getPageSize()),
                new QueryWrapper<ShoppingList>().orderByDesc("created_at"));
    }

    /** 勾选/取消勾选某明细已买。 */
    public void togglePurchased(Long itemId) {
        ShoppingItem it = itemMapper.selectById(itemId);
        if (it == null) return;
        int cur = it.getPurchased() == null ? 0 : it.getPurchased();
        it.setPurchased(cur == 1 ? 0 : 1);
        itemMapper.updateById(it);
    }

    /** 删除某明细。 */
    public void deleteItem(Long itemId) {
        itemMapper.deleteById(itemId);
    }

    /** 删除整张清单（逻辑删 list + 物理/逻辑删 item；此处 item 走物理删，避免遗留）。 */
    public void deleteList(Long listId) {
        itemMapper.delete(new QueryWrapper<ShoppingItem>().eq("list_id", listId));
        removeById(listId);
    }

    // ===================== 内部辅助 =====================

    /** 给 item 列表填中文展示名（食材名/单位名/品类名）。 */
    private List<ShoppingItemVO> fillVoNames(List<ShoppingItem> rows) {
        if (rows.isEmpty()) return new ArrayList<>();
        // 食材名
        List<Long> ingIds = rows.stream().map(ShoppingItem::getIngredientId).distinct().collect(Collectors.toList());
        Map<Long, String> ingName = ingredientMapper.selectList(new QueryWrapper<Ingredient>().in("id", ingIds))
                .stream().collect(Collectors.toMap(Ingredient::getId, Ingredient::getName, (a, b) -> a));
        // 单位 + 品类字典（一次性查两组）
        List<SysDict> dicts = dictMapper.selectList(
                new QueryWrapper<SysDict>().in("dict_group", List.of("unit", "purchase_category")));
        Map<Long, String> unitName = new HashMap<>();
        Map<Long, String> catName = new HashMap<>();
        for (SysDict d : dicts) {
            if ("unit".equals(d.getDictGroup())) unitName.put(d.getId(), d.getName());
            else if ("purchase_category".equals(d.getDictGroup())) catName.put(d.getId(), d.getName());
        }
        List<ShoppingItemVO> out = new ArrayList<>(rows.size());
        for (ShoppingItem it : rows) {
            ShoppingItemVO vo = new ShoppingItemVO();
            BeanUtils.copyProperties(it, vo);
            vo.setIngredientName(ingName.get(it.getIngredientId()));
            vo.setUnitName(unitName.get(it.getUnitId()));
            vo.setPurchaseCategoryName(catName.get(it.getPurchaseCategoryId()));
            out.add(vo);
        }
        return out;
    }
}
