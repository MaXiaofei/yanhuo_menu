-- V20: 采购清单模块（shopping_list / shopping_item）
-- 周计划(meal_plan_item)的各菜用量聚合 → 合并同食材(同单位) → 按采购品类分区 → 落库采购清单。
-- 不做估价（price 无意义、每次价格不固定）。食材/单位/品类分别复用 ingredient、sys_dict(group=unit/purchase_category)。

-- 采购清单主表：一次「按周计划生成」对应一条
CREATE TABLE IF NOT EXISTS shopping_list (
  id              BIGINT PRIMARY KEY AUTO_INCREMENT,
  source_plan_id  BIGINT,                          -- 来源周计划 meal_plan.id（可空，允许手工生成）
  time_range      VARCHAR(16),                     -- 时间范围标识（如 week / day）
  start_date      DATE,                            -- 起始日
  end_date        DATE,                            -- 结束日
  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
  deleted         TINYINT DEFAULT 0
);

-- 采购明细项：每行=某食材(某单位)的合并总量
CREATE TABLE IF NOT EXISTS shopping_item (
  id                    BIGINT PRIMARY KEY AUTO_INCREMENT,
  list_id               BIGINT NOT NULL,           -- 关联 shopping_list.id
  ingredient_id         BIGINT NOT NULL,           -- 关联 ingredient.id
  total_amount          DECIMAL(10,2) NOT NULL,    -- 合并后总量
  unit_id               BIGINT,                    -- 关联 sys_dict(group=unit)
  purchase_category_id  BIGINT,                    -- 关联 sys_dict(group=purchase_category)，前端分区用
  purchased             TINYINT DEFAULT 0,         -- 是否已买（0未买 1已买）
  UNIQUE KEY uk_list_ing_unit (list_id, ingredient_id, unit_id)
);

CREATE INDEX idx_shoppingitem_list ON shopping_item(list_id);
CREATE INDEX idx_shoppinglist_plan ON shopping_list(source_plan_id);
