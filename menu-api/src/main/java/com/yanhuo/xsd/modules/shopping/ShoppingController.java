package com.yanhuo.xsd.modules.shopping;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.yanhuo.xsd.common.PageQuery;
import com.yanhuo.xsd.common.R;
import com.yanhuo.xsd.modules.member.MpPerm;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 采购清单接口。范式照 pantry/mealplan：返回 R<T>，@Tag 分组。
 * 不做估价（price 无意义）。generate 走 @MpPerm(shopping.generate) 功能权限。
 */
@RestController
@RequestMapping("/shopping")
@RequiredArgsConstructor
@Tag(name = "采购清单")
public class ShoppingController {

    private final ShoppingService svc;

    /**
     * 从周计划生成采购清单：聚合各菜用量 → 合并同食材(同单位) → 品类分区 → 落库。
     * 返回新生成的 shopping_list.id。
     */
    @PostMapping("/generate")
    @MpPerm("shopping.generate")
    public R<Long> generate(@RequestParam Long planId,
                            @RequestParam(required = false, defaultValue = "week") String timeRange) {
        return R.ok(svc.generateFromPlan(planId, timeRange));
    }

    /** 采购清单详情：含 items（带中文：食材名/单位名/品类名）+ 按品类分区。 */
    @GetMapping("/{listId}")
    public R<ShoppingListVO> get(@PathVariable Long listId) {
        return R.ok(svc.getDetail(listId));
    }

    /** 采购清单分页列表（后台管理用）。 */
    @GetMapping
    public R<IPage<ShoppingList>> list(PageQuery q) {
        return R.ok(svc.page(q));
    }

    /** 勾选/取消勾选某明细已买。 */
    @PutMapping("/item/{itemId}/purchased")
    public R<?> togglePurchased(@PathVariable Long itemId) {
        svc.togglePurchased(itemId);
        return R.ok(null);
    }

    /** 删除某明细。 */
    @DeleteMapping("/item/{itemId}")
    public R<?> delItem(@PathVariable Long itemId) {
        svc.deleteItem(itemId);
        return R.ok(null);
    }

    /** 删除整张清单。 */
    @DeleteMapping("/{listId}")
    public R<?> delList(@PathVariable Long listId) {
        svc.deleteList(listId);
        return R.ok(null);
    }
}
