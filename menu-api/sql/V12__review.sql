-- 点评维度（复用 sys_dict，group=review_dimension；可在后台配置中心增删）
INSERT INTO sys_dict(dict_group, name, sort) VALUES
  ('review_dimension', '口味', 1),
  ('review_dimension', '难度', 2),
  ('review_dimension', '营养均衡', 3),
  ('review_dimension', '外观', 4);

CREATE TABLE review (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  dish_id BIGINT NOT NULL,
  member_id BIGINT NOT NULL,
  star_rating TINYINT NOT NULL,
  text VARCHAR(1024),
  images VARCHAR(2044),
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  deleted TINYINT DEFAULT 0
);
CREATE TABLE review_score (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  review_id BIGINT NOT NULL,
  dimension_id BIGINT NOT NULL,
  score TINYINT NOT NULL,
  UNIQUE KEY uk_rev_dim (review_id, dimension_id)
);
CREATE INDEX idx_review_dish ON review(dish_id);
