-- 点评维度（复用 sys_dict，group=review_dimension；可在后台配置中心增删）
INSERT INTO sys_dict(dict_group, name, sort) VALUES
  ('review_dimension', '口味', 1),
  ('review_dimension', '难度', 2),
  ('review_dimension', '营养均衡', 3),
  ('review_dimension', '外观', 4);
