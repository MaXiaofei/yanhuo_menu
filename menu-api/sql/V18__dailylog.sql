-- V18: 每日饮食记录模块（dailylog）
-- daily_log：某就餐成员某日的饮食记录（备注），daily_log_item：该日各摄入项（菜品份数 / 食材克数）。
-- 营养汇总由后端按 items 实时聚合（复用 NutritionCalcService），不冗余存储。
CREATE TABLE IF NOT EXISTS daily_log (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  member_id   BIGINT NOT NULL,                -- 关联 member.id（当前就餐成员）
  `date`      DATE NOT NULL,                  -- 记录日期
  note        VARCHAR(512),                   -- 备注（如「今天吃了零食」）
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  deleted     TINYINT DEFAULT 0               -- 逻辑删除
);

CREATE TABLE IF NOT EXISTS daily_log_item (
  id             BIGINT PRIMARY KEY AUTO_INCREMENT,
  log_id         BIGINT NOT NULL,             -- 关联 daily_log.id
  dish_id        BIGINT,                      -- 摄入菜品（与 ingredient_id 二选一）
  ingredient_id  BIGINT,                      -- 摄入食材
  amount         DECIMAL(10,2),               -- 克(ingredient) 或 份数(dish)
  serving_factor DECIMAL(4,2) DEFAULT 1,      -- 份数缩放系数（dish 项）
  INDEX idx_log (log_id)
);

CREATE INDEX idx_dailylog_member_date ON daily_log(member_id, `date`);
