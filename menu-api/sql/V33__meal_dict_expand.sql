-- V33: 餐段字典扩展（4餐→6餐）
-- 新增：上午加餐(09:00-11:30)、下午加餐(14:00-17:00)、夜宵(20:00-23:00)
-- 保留原有 早餐/午餐/晚餐/加餐，调整 sort 顺序

-- 先清理旧的 meal 字典（保留幂等）
DELETE FROM sys_dict WHERE dict_group = 'meal';

-- 重新插入完整的 6 餐段
INSERT INTO sys_dict(dict_group, name, sort) VALUES
  ('meal', '早餐', 1),
  ('meal', '上午加餐', 2),
  ('meal', '午餐', 3),
  ('meal', '下午加餐', 4),
  ('meal', '晚餐', 5),
  ('meal', '夜宵', 6);
