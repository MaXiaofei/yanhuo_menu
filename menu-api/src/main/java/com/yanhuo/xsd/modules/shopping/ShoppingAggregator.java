package com.yanhuo.xsd.modules.shopping;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 采购清单合并算法（纯函数，算法地基）。
 *
 * <p>不依赖任何 Mapper / Spring 状态，可单测。参照 {@code MenuCalcService} 范式。
 *
 * <p>合并规则：
 * <ul>
 *   <li>按 (ingredientId, unitId) 分组，同组 amount 相加 → 一行 ShoppingLine；</li>
 *   <li>同食材不同单位：不合并，分别成行；</li>
 *   <li>purchaseCategoryId 仅随组携带（同组内若有不同品类，取首条；正常场景下同食材品类一致）。</li>
 * </ul>
 */
@Component
public class ShoppingAggregator {

    /** 一笔用量：某食材在某单位下用掉多少（来自某道菜的 dish_ingredient，已 join ingredient）。 */
    public record Usage(Long ingredientId, Long unitId, BigDecimal amount, Long purchaseCategoryId) {}

    /** 合并后的一行采购明细。 */
    public record ShoppingLine(Long ingredientId, Long unitId, BigDecimal totalAmount, Long purchaseCategoryId) {}

    /** 分组键：食材 + 单位（不同单位不合并）。 */
    private record Key(Long ingredientId, Long unitId) {}

    /**
     * 聚合：把多笔用量按 (ingredientId, unitId) 合并，amount 相加。
     *
     * @param usages 用量列表，可空
     * @return 合并后的采购行（无稳定顺序保证，按首次出现顺序）
     */
    public List<ShoppingLine> aggregate(List<Usage> usages) {
        if (usages == null || usages.isEmpty()) return new ArrayList<>();
        Map<Key, ShoppingLine> acc = new LinkedHashMap<>();
        for (Usage u : usages) {
            if (u == null) continue;
            BigDecimal amt = u.amount() == null ? BigDecimal.ZERO : u.amount();
            Key k = new Key(u.ingredientId(), u.unitId());
            ShoppingLine cur = acc.get(k);
            if (cur == null) {
                acc.put(k, new ShoppingLine(u.ingredientId(), u.unitId(), amt, u.purchaseCategoryId()));
            } else {
                acc.put(k, new ShoppingLine(
                        cur.ingredientId(), cur.unitId(),
                        cur.totalAmount().add(amt),
                        cur.purchaseCategoryId()));
            }
        }
        return new ArrayList<>(acc.values());
    }

    /**
     * 按采购品类(purchaseCategoryId)分区：先 aggregate 合并，再按品类分组。
     *
     * @return categoryId -> 该品类下的采购行列表（null 品类归到 key=null）
     */
    public Map<Long, List<ShoppingLine>> groupByCategory(List<Usage> usages) {
        List<ShoppingLine> lines = aggregate(usages);
        Map<Long, List<ShoppingLine>> grouped = new LinkedHashMap<>();
        for (ShoppingLine l : lines) {
            Long cat = l.purchaseCategoryId();  // null 品类归到 key=null 一组
            grouped.computeIfAbsent(cat, k -> new ArrayList<>()).add(l);
        }
        return grouped;
    }
}
