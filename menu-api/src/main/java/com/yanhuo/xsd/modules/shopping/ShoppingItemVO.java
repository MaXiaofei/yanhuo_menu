package com.yanhuo.xsd.modules.shopping;

import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;

/**
 * 采购明细 VO：在 ShoppingItem 基础上挂中文展示名（食材名/单位名/品类名）。
 * 参照 PantryVO 范式。枚举铁律：前端只拿中文 name。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class ShoppingItemVO extends ShoppingItem {

    /** 食材名（join ingredient）。 */
    private String ingredientName;

    /** 单位名（join sys_dict group=unit）。 */
    private String unitName;

    /** 采购品类名（join sys_dict group=purchase_category）。 */
    private String purchaseCategoryName;
}
