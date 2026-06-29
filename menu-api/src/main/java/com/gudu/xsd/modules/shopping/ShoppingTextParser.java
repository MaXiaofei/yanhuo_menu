package com.gudu.xsd.modules.shopping;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 采购清单文本解析器（纯 Java，不依赖 AI）。
 *
 * <p>输入示例：
 * <pre>
 *   土豆 3斤
 *   排骨 2斤
 *   生抽 1瓶
 *   青椒 200g
 * </pre>
 *
 * <p>解析规则：
 * <ol>
 *   <li>按行分割，跳过纯空行和纯标点行</li>
 *   <li>每行匹配：名称 + 数量 + 单位（中间可有空格分隔）</li>
 *   <li>单位标准化：斤→500g, 公斤→1000g, 两→50g, 克/g 保持</li>
 *   <li>瓶/个/袋等离散单位不换算重量，保留原始数量 + 单位名</li>
 * </ol>
 */
public class ShoppingTextParser {

    private static final Pattern LINE_PATTERN = Pattern.compile(
            "^(.+?)\\s*(\\d+\\.?\\d*)\\s*(斤|公斤|千克|kg|克|g|两|瓶|个|袋|包|盒|罐|升|L|ml|毫升|把|根|条|块|只|颗|粒)?\\s*$"
    );

    /**
     * 解析结果：一行文本 → 结构化采购项。
     */
    public record ParsedItem(
            String name,           // 食材名（trim 后）
            BigDecimal quantity,   // 数量
            String unitName,       // 单位名（斤/瓶/g/...），可为 null
            BigDecimal gramsEstimate // 估算克数（重量单位可换算；个/瓶等离散单位填 null）
    ) {}

    /**
     * 解析整段文本，返回采购项列表。
     */
    public List<ParsedItem> parse(String text) {
        if (text == null || text.isBlank()) return List.of();
        List<ParsedItem> items = new ArrayList<>();
        for (String rawLine : text.split("\\n")) {
            String line = rawLine.trim();
            if (line.isEmpty()) continue;
            // 跳过明显不是食材行的行（纯数字、纯标点、过长行）
            if (line.length() > 80) continue;
            if (line.matches("^[\\d.,，。、；;：:！!？?]+$")) continue;

            ParsedItem item = parseLine(line);
            if (item != null) items.add(item);
        }
        return items;
    }

    private ParsedItem parseLine(String line) {
        Matcher m = LINE_PATTERN.matcher(line);
        if (!m.matches()) {
            // 宽松匹配：无数量单位，整行当食材名
            String name = line.replaceAll("\\s+", " ").trim();
            if (name.isEmpty() || name.length() > 30) return null;
            return new ParsedItem(name, BigDecimal.ONE, null, null);
        }

        String name = m.group(1).trim();
        if (name.isEmpty() || name.length() > 30) return null;

        BigDecimal quantity;
        try {
            quantity = new BigDecimal(m.group(2));
        } catch (NumberFormatException e) {
            quantity = BigDecimal.ONE;
        }
        if (quantity.compareTo(BigDecimal.ZERO) <= 0) return null;

        String unit = m.group(3) != null ? m.group(3).trim() : null;
        BigDecimal grams = toGrams(quantity, unit);

        return new ParsedItem(name, quantity, unit, grams);
    }

    /**
     * 将数量+单位换算为估算克数。离散单位（个/瓶/袋等）返回 null。
     */
    static BigDecimal toGrams(BigDecimal quantity, String unit) {
        if (unit == null) return null;
        return switch (unit) {
            case "斤" -> quantity.multiply(new BigDecimal("500"));
            case "公斤", "千克", "kg" -> quantity.multiply(new BigDecimal("1000"));
            case "两" -> quantity.multiply(new BigDecimal("50"));
            case "克", "g" -> quantity;
            case "升", "L" -> quantity.multiply(new BigDecimal("1000"));  // 1L≈1000g (水类)
            case "ml", "毫升" -> quantity;  // 1ml≈1g
            // 离散单位：瓶/个/袋/包/盒/罐/把/根/条/块/只/颗/粒 → 不换算重量
            default -> null;
        };
    }

    /**
     * 按名称匹配食材库，返回 ingredientId（精确匹配优先，部分匹配兜底）。
     */
    public static Long matchIngredient(String name, List<IngredientRef> ingredientPool) {
        String n = name.trim();
        // 精确匹配
        for (IngredientRef ing : ingredientPool) {
            if (ing.name.equals(n)) return ing.id;
        }
        // 包含匹配（输入名包含食材名 或 食材名包含输入名）
        for (IngredientRef ing : ingredientPool) {
            if (ing.name.contains(n) || n.contains(ing.name)) return ing.id;
        }
        return null;
    }

    /**
     * 食材引用：id + name（轻量，避免全量实体）。
     */
    public record IngredientRef(Long id, String name, Long purchaseCategoryId) {}
}
