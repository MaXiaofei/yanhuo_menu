package com.gudu.xsd.modules.mealplan;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@TableName("meal_plan_item")
public class MealPlanItem {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long planId;

    /** 排菜日期。 */
    private LocalDate date;

    /** 餐次：关联 sys_dict(group=meal)（早餐/午餐/晚餐/加餐）。 */
    private String meal;

    private Long dishId;

    /** 份数系数。 */
    private BigDecimal servingFactor;

    private Integer sort;

    /** 菜品名（非 DB 字段，getPlan 时 JOIN 填充）。 */
    @TableField(exist = false)
    private String dishName;
}
