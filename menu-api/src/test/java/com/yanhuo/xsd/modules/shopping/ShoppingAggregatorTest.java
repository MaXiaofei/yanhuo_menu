package com.yanhuo.xsd.modules.shopping;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 采购清单合并算法纯函数测试（核心算法 TDD）。
 * 参照 MenuCalcService / PantryService 范式：不依赖 Spring，直接 new ShoppingAggregator()。
 *
 * 算法契约：
 *  - 同食材同单位：用量相加合并；
 *  - 同食材不同单位：不合并，分开成两行；
 *  - 按采购品类(purchaseCategoryId)分区。
 */
class ShoppingAggregatorTest {

    private final ShoppingAggregator agg = new ShoppingAggregator();

    @Test
    void 同食材同单位_用量相加合并() {
        var usages = List.of(
                new ShoppingAggregator.Usage(1L, 20L, new BigDecimal("300"), 24L),   // 番茄 300g（番茄炒蛋）
                new ShoppingAggregator.Usage(1L, 20L, new BigDecimal("200"), 24L),   // 番茄 200g（另一道菜）
                new ShoppingAggregator.Usage(2L, 20L, new BigDecimal("180"), 27L));  // 鸡蛋 180g
        var lines = agg.aggregate(usages);
        assertThat(lines).hasSize(2);  // 番茄、鸡蛋
        var tomato = lines.stream().filter(l -> l.ingredientId() == 1L).findFirst().get();
        assertThat(tomato.totalAmount()).isEqualByComparingTo("500");  // 300+200
        assertThat(tomato.unitId()).isEqualTo(20L);
        assertThat(tomato.purchaseCategoryId()).isEqualTo(24L);
    }

    @Test
    void 同食材不同单位_不合并() {
        var usages = List.of(
                new ShoppingAggregator.Usage(1L, 20L, new BigDecimal("300"), 24L),   // 番茄 300g
                new ShoppingAggregator.Usage(1L, 22L, new BigDecimal("2"), 24L));    // 番茄 2个
        assertThat(agg.aggregate(usages)).hasSize(2);  // 不同单位分开
    }

    @Test
    void 三道菜交叉_部分合并部分分开() {
        var usages = List.of(
                new ShoppingAggregator.Usage(1L, 20L, new BigDecimal("300"), 24L),
                new ShoppingAggregator.Usage(1L, 20L, new BigDecimal("150"), 24L),   // 番茄 450g
                new ShoppingAggregator.Usage(1L, 22L, new BigDecimal("1"), 24L),     // 番茄 1个（另一单位）
                new ShoppingAggregator.Usage(2L, 20L, new BigDecimal("180"), 27L),
                new ShoppingAggregator.Usage(2L, 20L, new BigDecimal("120"), 27L));  // 鸡蛋 300g
        var lines = agg.aggregate(usages);
        assertThat(lines).hasSize(3);  // 番茄g、番茄个、鸡蛋g
        var tomatoG = lines.stream()
                .filter(l -> l.ingredientId() == 1L && l.unitId() == 20L).findFirst().get();
        assertThat(tomatoG.totalAmount()).isEqualByComparingTo("450");
        var egg = lines.stream()
                .filter(l -> l.ingredientId() == 2L).findFirst().get();
        assertThat(egg.totalAmount()).isEqualByComparingTo("300");
    }

    @Test
    void 空用量_返回空列表() {
        assertThat(agg.aggregate(List.of())).isEmpty();
        assertThat(agg.aggregate(null)).isEmpty();
    }

    @Test
    void 按采购品类分区() {
        var usages = List.of(
                new ShoppingAggregator.Usage(1L, 20L, new BigDecimal("300"), 24L),   // 蔬菜
                new ShoppingAggregator.Usage(1L, 20L, new BigDecimal("200"), 24L),   // 蔬菜（合并）
                new ShoppingAggregator.Usage(2L, 20L, new BigDecimal("180"), 27L));  // 蛋类
        var grouped = agg.groupByCategory(usages);
        assertThat(grouped.keySet()).containsExactlyInAnyOrder(24L, 27L);
        assertThat(grouped.get(24L)).hasSize(1);  // 番茄合并后 1 行
        assertThat(grouped.get(27L)).hasSize(1);
        assertThat(grouped.get(24L).get(0).totalAmount()).isEqualByComparingTo("500");
    }

    @Test
    void 品类分区_未知品类归一组() {
        var usages = List.of(
                new ShoppingAggregator.Usage(3L, 20L, new BigDecimal("50"), null),   // 无品类
                new ShoppingAggregator.Usage(4L, 20L, new BigDecimal("60"), null));  // 无品类
        var grouped = agg.groupByCategory(usages);
        assertThat(grouped.keySet()).containsExactlyInAnyOrder((Long) null);
        assertThat(grouped.get(null)).hasSize(2);
    }
}
