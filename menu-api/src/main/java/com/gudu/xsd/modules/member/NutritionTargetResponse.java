package com.gudu.xsd.modules.member;

import lombok.Data;

/**
 * 成员每日营养目标（热量 + 三大宏量），前端精准模式使用。
 */
@Data
public class NutritionTargetResponse {

    /** 每日热量目标（kcal）。已含活动水平 + 体控目标调整。 */
    private int calorieTarget;

    /** 蛋白目标（g）。 */
    private int proteinTarget;

    /** 碳水目标（g）。 */
    private int carbTarget;

    /** 脂肪目标（g）。 */
    private int fatTarget;

    /** 体控目标（MAINTAIN/LOSE/GAIN/null）。 */
    private String goal;

    /** BMR (kcal/day)，仅供参考。 */
    private int bmr;
}
