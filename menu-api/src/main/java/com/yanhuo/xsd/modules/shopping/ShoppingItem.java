package com.yanhuo.xsd.modules.shopping;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 采购明细项：每行 = 某食材(某单位)合并后的总量。
 * 同 list 内 (ingredient_id, unit_id) 唯一；unit_id/purchase_category_id 关联 sys_dict。
 */
@Data
@TableName("shopping_item")
public class ShoppingItem {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long listId;

    private Long ingredientId;

    /** 合并后总量。 */
    private BigDecimal totalAmount;

    private Long unitId;

    private Long purchaseCategoryId;

    /** 是否已买（0 未买 / 1 已买）。 */
    private Integer purchased;
}
