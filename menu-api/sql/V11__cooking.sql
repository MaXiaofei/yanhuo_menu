-- 烹饪记录（也用于「做过」标记）
CREATE TABLE IF NOT EXISTS cooking_record (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  dish_id     BIGINT NOT NULL,
  member_id   BIGINT,
  cooked_at   DATETIME,
  note        VARCHAR(512),
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP
);
