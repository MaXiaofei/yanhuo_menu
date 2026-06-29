package com.gudu.xsd.modules.pantry;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 食材单位推断器（纯规则，不调 AI）。
 *
 * <p>按名称关键词匹配推荐计量单位。规则表按「大类 → 关键词 → 单位」组织，
 * 匹配顺序即定义顺序（先匹配先生效）。
 */
public class UnitMatcher {

    /**
     * 关键词 → 推荐单位。按匹配优先级排列（更具体的词放前面）。
     */
    private static final LinkedHashMap<String, String> KEYWORD_UNIT = new LinkedHashMap<>();

    static {
        // 液体/饮品
        put("奶", "盒"); put("牛奶", "盒"); put("酸奶", "盒"); put("豆浆", "杯");
        put("油", "瓶"); put("酱油", "瓶"); put("醋", "瓶"); put("料酒", "瓶");
        put("饮料", "瓶"); put("水", "瓶"); put("酒", "瓶");
        put("蜂蜜", "瓶"); put("果酱", "瓶");
        // 调味料
        put("盐", "袋"); put("糖", "袋"); put("味精", "袋"); put("鸡精", "袋");
        put("生抽", "瓶"); put("老抽", "瓶"); put("蚝油", "瓶");
        put("酱", "瓶"); put("辣椒", "瓶"); put("花椒", "袋"); put("八角", "袋");
        put("胡椒粉", "瓶");
        // 肉类（按斤/克）
        put("排骨", "斤"); put("五花肉", "斤"); put("里脊", "斤");
        put("牛肉", "斤"); put("羊肉", "斤"); put("猪肉", "斤"); put("鸡肉", "斤");
        put("鸭肉", "斤"); put("鸡腿", "斤"); put("鸡翅", "斤"); put("鸡胸", "斤");
        put("肉", "斤"); put("鱼", "条"); put("虾", "斤"); put("蟹", "只");
        put("蛋", "个"); put("鸡蛋", "个"); put("鸭蛋", "个");
        // 蔬菜
        put("白菜", "颗"); put("包菜", "颗"); put("生菜", "把");
        put("土豆", "个"); put("番茄", "个"); put("西红柿", "个");
        put("黄瓜", "根"); put("胡萝卜", "根"); put("茄子", "个");
        put("玉米", "根"); put("红薯", "个");
        put("葱", "把"); put("姜", "块"); put("蒜", "头");
        put("辣椒", "个"); put("青椒", "个"); put("红椒", "个");
        put("菇", "盒"); put("香菇", "盒"); put("金针菇", "盒");
        put("菜", "把");
        // 水果
        put("苹果", "个"); put("香蕉", "根"); put("梨", "个"); put("桃", "个");
        put("西瓜", "个"); put("葡萄", "串"); put("草莓", "盒");
        put("蓝莓", "盒"); put("樱桃", "盒");
        put("水果", "个");
        // 干货/主食
        put("米", "袋"); put("面", "袋"); put("面粉", "袋");
        put("面条", "把"); put("粉条", "袋");
        put("豆", "袋"); put("绿豆", "袋"); put("红豆", "袋");
        // 其他
        put("豆腐", "块"); put("豆浆", "杯");
        put("面包", "个"); put("馒头", "个");
    }

    private static void put(String key, String unit) {
        KEYWORD_UNIT.putIfAbsent(key, unit);
    }

    /**
     * 根据食材名推断推荐计量单位。
     *
     * @param name 食材名（如"牛奶""排骨"）
     * @return 推荐单位（如"盒""斤"），无匹配返回 "g"
     */
    public static String match(String name) {
        if (name == null || name.isBlank()) return "g";
        for (Map.Entry<String, String> e : KEYWORD_UNIT.entrySet()) {
            if (name.contains(e.getKey())) return e.getValue();
        }
        return "g";
    }
}
