-- ============================================================
-- V14 MVP 演示数据：真实家常食材 + 准确营养(参考《中国食物成分表》)
-- + 8 道家常菜 + 3 个家庭菜单 + 5 名家庭成员(含三高/宝宝场景)
-- 特性：幂等(可重复灌)、关联用 INSERT...SELECT by name(不硬编码 id)
-- 营养指标(per 100g)：1=calorie(kcal) 2=protein(g) 3=fat(g) 4=carb(g) 5=sugar(g) 6=gi
-- ============================================================

START TRANSACTION;

-- ---------- 幂等清理：按 name 删除 demo 数据(先删子表，遵循外键顺序) ----------
DELETE md FROM menu_dish md
  JOIN menu m ON m.id = md.menu_id
  WHERE m.name IN ('周末家宴','老人清淡餐','宝宝辅食餐');
DELETE FROM menu_dish md
  WHERE md.menu_id IN (SELECT id FROM (SELECT id FROM menu WHERE name IN ('周末家宴','老人清淡餐','宝宝辅食餐')) t);
DELETE FROM menu WHERE name IN ('周末家宴','老人清淡餐','宝宝辅食餐');

DELETE di FROM dish_ingredient di
  JOIN dish d ON d.id = di.dish_id
  WHERE d.name IN ('番茄炒蛋','青椒土豆丝','蒜蓉西蓝花','清炒虾仁','香煎鸡胸肉','肉末豆腐','凉拌黄瓜','蒸蛋羹');
DELETE dd FROM dish_dict dd
  JOIN dish d ON d.id = dd.dish_id
  WHERE d.name IN ('番茄炒蛋','青椒土豆丝','蒜蓉西蓝花','清炒虾仁','香煎鸡胸肉','肉末豆腐','凉拌黄瓜','蒸蛋羹');
DELETE ds FROM dish_step ds
  JOIN dish d ON d.id = ds.dish_id
  WHERE d.name IN ('番茄炒蛋','青椒土豆丝','蒜蓉西蓝花','清炒虾仁','香煎鸡胸肉','肉末豆腐','凉拌黄瓜','蒸蛋羹');
DELETE FROM dish WHERE name IN ('番茄炒蛋','青椒土豆丝','蒜蓉西蓝花','清炒虾仁','香煎鸡胸肉','肉末豆腐','凉拌黄瓜','蒸蛋羹');

DELETE inn FROM ingredient_nutrition inn
  JOIN ingredient i ON i.id = inn.ingredient_id
  WHERE i.name IN ('番茄','鸡蛋','猪肉(瘦)','鸡胸肉','牛肉(瘦)','虾仁','草鱼','豆腐(北)','西蓝花','土豆','胡萝卜','黄瓜','大白菜','青椒','米饭','食用油','白糖','食盐');
DELETE FROM ingredient WHERE name IN ('番茄','鸡蛋','猪肉(瘦)','鸡胸肉','牛肉(瘦)','虾仁','草鱼','豆腐(北)','西蓝花','土豆','胡萝卜','黄瓜','大白菜','青椒','米饭','食用油','白糖','食盐');

DELETE FROM member WHERE name IN ('张爸爸','张妈妈','张爷爷','张奶奶','小宝');

-- ============================================================
-- 1. 成员(5个，含三高/宝宝场景)
-- ============================================================
INSERT INTO member(name, role_tags, health_profile) VALUES
  ('张爸爸', '32', '{"height":175,"weight":75,"allergies":[],"audiences":[]}'),
  ('张妈妈', '34', '{"height":162,"weight":58,"allergies":[],"audiences":[]}'),
  ('张爷爷', '34', '{"height":170,"weight":68,"audiences":["高血压"],"constraints":{"sodiumMaxMg":2000}}'),
  ('张奶奶', '34', '{"height":160,"weight":60,"audiences":["高血糖"],"constraints":{"sugarMaxG":25,"giMax":55}}'),
  ('小宝',   '34', '{"height":75,"weight":10,"ageMonth":12,"audiences":["宝宝辅食"]}');

-- ============================================================
-- 2. 食材(18个)  注：任务表头写17个但实列出18行(含食盐)，按18行写入
-- ============================================================
INSERT INTO ingredient(name, unit_id, price, purchase_category_id) VALUES
  ('番茄',    20,  5, 24),
  ('鸡蛋',    20,  8, 27),
  ('猪肉(瘦)', 20, 25, 25),
  ('鸡胸肉',  20, 18, 25),
  ('牛肉(瘦)', 20, 50, 25),
  ('虾仁',    20, 60, 26),
  ('草鱼',    20, 15, 26),
  ('豆腐(北)', 20,  5, 28),
  ('西蓝花',  20,  8, 24),
  ('土豆',    20,  4, 24),
  ('胡萝卜',  20,  4, 24),
  ('黄瓜',    20,  4, 24),
  ('大白菜',  20,  3, 24),
  ('青椒',    20,  6, 24),
  ('米饭',    20,  2, 30),
  ('食用油',  21, 15, 30),
  ('白糖',    20,  8, 30),
  ('食盐',    20,  3, 30);

-- ---- 营养 EAV(per 100g)：[calorie(1), protein(2), fat(3), carb(4), sugar(5), gi(6)] ----
-- 番茄 19/0.9/0.2/4.0/2.6/30
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,19   FROM ingredient WHERE name='番茄';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,0.9  FROM ingredient WHERE name='番茄';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,0.2  FROM ingredient WHERE name='番茄';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,4.0  FROM ingredient WHERE name='番茄';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,2.6  FROM ingredient WHERE name='番茄';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,30   FROM ingredient WHERE name='番茄';
-- 鸡蛋 144/13.3/8.8/2.8/1.5/30
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,144  FROM ingredient WHERE name='鸡蛋';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,13.3 FROM ingredient WHERE name='鸡蛋';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,8.8  FROM ingredient WHERE name='鸡蛋';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,2.8  FROM ingredient WHERE name='鸡蛋';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,1.5  FROM ingredient WHERE name='鸡蛋';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,30   FROM ingredient WHERE name='鸡蛋';
-- 猪肉(瘦) 143/20.3/6.2/1.5/0.9/0
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,143  FROM ingredient WHERE name='猪肉(瘦)';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,20.3 FROM ingredient WHERE name='猪肉(瘦)';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,6.2  FROM ingredient WHERE name='猪肉(瘦)';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,1.5  FROM ingredient WHERE name='猪肉(瘦)';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,0.9  FROM ingredient WHERE name='猪肉(瘦)';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,0    FROM ingredient WHERE name='猪肉(瘦)';
-- 鸡胸肉 133/19.4/5.0/2.5/0/0
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,133  FROM ingredient WHERE name='鸡胸肉';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,19.4 FROM ingredient WHERE name='鸡胸肉';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,5.0  FROM ingredient WHERE name='鸡胸肉';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,2.5  FROM ingredient WHERE name='鸡胸肉';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,0    FROM ingredient WHERE name='鸡胸肉';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,0    FROM ingredient WHERE name='鸡胸肉';
-- 牛肉(瘦) 125/20.2/4.2/1.2/0.6/0
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,125  FROM ingredient WHERE name='牛肉(瘦)';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,20.2 FROM ingredient WHERE name='牛肉(瘦)';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,4.2  FROM ingredient WHERE name='牛肉(瘦)';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,1.2  FROM ingredient WHERE name='牛肉(瘦)';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,0.6  FROM ingredient WHERE name='牛肉(瘦)';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,0    FROM ingredient WHERE name='牛肉(瘦)';
-- 虾仁 48/10.4/0.7/0/0/0
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,48   FROM ingredient WHERE name='虾仁';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,10.4 FROM ingredient WHERE name='虾仁';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,0.7  FROM ingredient WHERE name='虾仁';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,0    FROM ingredient WHERE name='虾仁';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,0    FROM ingredient WHERE name='虾仁';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,0    FROM ingredient WHERE name='虾仁';
-- 草鱼 113/16.6/5.2/0/0/0
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,113  FROM ingredient WHERE name='草鱼';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,16.6 FROM ingredient WHERE name='草鱼';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,5.2  FROM ingredient WHERE name='草鱼';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,0    FROM ingredient WHERE name='草鱼';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,0    FROM ingredient WHERE name='草鱼';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,0    FROM ingredient WHERE name='草鱼';
-- 豆腐(北) 98/12.2/4.8/1.5/0.5/15
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,98   FROM ingredient WHERE name='豆腐(北)';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,12.2 FROM ingredient WHERE name='豆腐(北)';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,4.8  FROM ingredient WHERE name='豆腐(北)';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,1.5  FROM ingredient WHERE name='豆腐(北)';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,0.5  FROM ingredient WHERE name='豆腐(北)';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,15   FROM ingredient WHERE name='豆腐(北)';
-- 西蓝花 36/4.1/0.6/4.3/1.7/15
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,36   FROM ingredient WHERE name='西蓝花';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,4.1  FROM ingredient WHERE name='西蓝花';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,0.6  FROM ingredient WHERE name='西蓝花';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,4.3  FROM ingredient WHERE name='西蓝花';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,1.7  FROM ingredient WHERE name='西蓝花';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,15   FROM ingredient WHERE name='西蓝花';
-- 土豆 77/2.0/0.2/17.2/0.8/78
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,77   FROM ingredient WHERE name='土豆';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,2.0  FROM ingredient WHERE name='土豆';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,0.2  FROM ingredient WHERE name='土豆';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,17.2 FROM ingredient WHERE name='土豆';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,0.8  FROM ingredient WHERE name='土豆';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,78   FROM ingredient WHERE name='土豆';
-- 胡萝卜 39/1.0/0.2/8.8/4.7/71
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,39   FROM ingredient WHERE name='胡萝卜';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,1.0  FROM ingredient WHERE name='胡萝卜';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,0.2  FROM ingredient WHERE name='胡萝卜';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,8.8  FROM ingredient WHERE name='胡萝卜';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,4.7  FROM ingredient WHERE name='胡萝卜';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,71   FROM ingredient WHERE name='胡萝卜';
-- 黄瓜 16/0.8/0.2/2.9/2.3/15
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,16   FROM ingredient WHERE name='黄瓜';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,0.8  FROM ingredient WHERE name='黄瓜';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,0.2  FROM ingredient WHERE name='黄瓜';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,2.9  FROM ingredient WHERE name='黄瓜';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,2.3  FROM ingredient WHERE name='黄瓜';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,15   FROM ingredient WHERE name='黄瓜';
-- 大白菜 20/1.5/0.1/3.4/1.7/15
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,20   FROM ingredient WHERE name='大白菜';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,1.5  FROM ingredient WHERE name='大白菜';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,0.1  FROM ingredient WHERE name='大白菜';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,3.4  FROM ingredient WHERE name='大白菜';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,1.7  FROM ingredient WHERE name='大白菜';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,15   FROM ingredient WHERE name='大白菜';
-- 青椒 22/1.0/0.2/5.4/5.1/15
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,22   FROM ingredient WHERE name='青椒';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,1.0  FROM ingredient WHERE name='青椒';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,0.2  FROM ingredient WHERE name='青椒';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,5.4  FROM ingredient WHERE name='青椒';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,5.1  FROM ingredient WHERE name='青椒';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,15   FROM ingredient WHERE name='青椒';
-- 米饭 116/2.6/0.3/25.9/0/83
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,116  FROM ingredient WHERE name='米饭';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,2.6  FROM ingredient WHERE name='米饭';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,0.3  FROM ingredient WHERE name='米饭';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,25.9 FROM ingredient WHERE name='米饭';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,0    FROM ingredient WHERE name='米饭';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,83   FROM ingredient WHERE name='米饭';
-- 食用油 899/0/99.9/0/0/0
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,899  FROM ingredient WHERE name='食用油';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,0    FROM ingredient WHERE name='食用油';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,99.9 FROM ingredient WHERE name='食用油';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,0    FROM ingredient WHERE name='食用油';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,0    FROM ingredient WHERE name='食用油';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,0    FROM ingredient WHERE name='食用油';
-- 白糖 400/0/0/99.9/99.9/0
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,400  FROM ingredient WHERE name='白糖';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,0    FROM ingredient WHERE name='白糖';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,0    FROM ingredient WHERE name='白糖';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,99.9 FROM ingredient WHERE name='白糖';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,99.9 FROM ingredient WHERE name='白糖';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,0    FROM ingredient WHERE name='白糖';
-- 食盐 0/0/0/0/0/0
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,1,0    FROM ingredient WHERE name='食盐';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,2,0    FROM ingredient WHERE name='食盐';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,3,0    FROM ingredient WHERE name='食盐';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,4,0    FROM ingredient WHERE name='食盐';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,5,0    FROM ingredient WHERE name='食盐';
INSERT INTO ingredient_nutrition(ingredient_id, metric_id, value) SELECT id,6,0    FROM ingredient WHERE name='食盐';

-- ============================================================
-- 3. 菜品(8道家常菜) + 步骤 + 关联 + 食材用量
-- ============================================================

-- 3.1 番茄炒蛋 category=8 cuisine=1 tag=4,5  diff=2 prep=5 cook=10 price=15
INSERT INTO dish(name, note, prep_time, cook_time, price, difficulty) VALUES ('番茄炒蛋','家常经典，酸甜下饭',5,10,15,2);
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,1,'番茄洗净切块',1 FROM dish WHERE name='番茄炒蛋';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,2,'鸡蛋打散，热油炒熟盛出',2 FROM dish WHERE name='番茄炒蛋';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,3,'锅中热油炒番茄出汁，加糖盐调味',3 FROM dish WHERE name='番茄炒蛋';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,4,'倒回鸡蛋翻炒均匀出锅',4 FROM dish WHERE name='番茄炒蛋';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,8,'category' FROM dish WHERE name='番茄炒蛋';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,1,'cuisine'  FROM dish WHERE name='番茄炒蛋';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,4,'tag'      FROM dish WHERE name='番茄炒蛋';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,5,'tag'      FROM dish WHERE name='番茄炒蛋';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 300 FROM dish d, ingredient i WHERE d.name='番茄炒蛋' AND i.name='番茄';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 180 FROM dish d, ingredient i WHERE d.name='番茄炒蛋' AND i.name='鸡蛋';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15  FROM dish d, ingredient i WHERE d.name='番茄炒蛋' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 3   FROM dish d, ingredient i WHERE d.name='番茄炒蛋' AND i.name='食盐';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 5   FROM dish d, ingredient i WHERE d.name='番茄炒蛋' AND i.name='白糖';

-- 3.2 青椒土豆丝 category=8 tag=4 diff=2 prep=10 cook=8
INSERT INTO dish(name, note, prep_time, cook_time, price, difficulty) VALUES ('青椒土豆丝','爽脆下饭',10,8,8,2);
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,1,'土豆、青椒切丝',1 FROM dish WHERE name='青椒土豆丝';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,2,'土豆丝泡水去淀粉',2 FROM dish WHERE name='青椒土豆丝';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,3,'热油大火炒土豆丝',3 FROM dish WHERE name='青椒土豆丝';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,4,'加青椒丝、盐翻炒均匀',4 FROM dish WHERE name='青椒土豆丝';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,8,'category' FROM dish WHERE name='青椒土豆丝';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,4,'tag'      FROM dish WHERE name='青椒土豆丝';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 300 FROM dish d, ingredient i WHERE d.name='青椒土豆丝' AND i.name='土豆';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 100 FROM dish d, ingredient i WHERE d.name='青椒土豆丝' AND i.name='青椒';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10  FROM dish d, ingredient i WHERE d.name='青椒土豆丝' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 3   FROM dish d, ingredient i WHERE d.name='青椒土豆丝' AND i.name='食盐';

-- 3.3 蒜蓉西蓝花 category=8 cuisine=3 tag=7 diff=1 prep=5 cook=5
INSERT INTO dish(name, note, prep_time, cook_time, price, difficulty) VALUES ('蒜蓉西蓝花','清淡营养',5,5,10,1);
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,1,'西蓝花掰小朵焯水',1 FROM dish WHERE name='蒜蓉西蓝花';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,2,'热油爆香蒜末',2 FROM dish WHERE name='蒜蓉西蓝花';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,3,'下西蓝花大火翻炒',3 FROM dish WHERE name='蒜蓉西蓝花';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,4,'加盐出锅',4 FROM dish WHERE name='蒜蓉西蓝花';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,8,'category' FROM dish WHERE name='蒜蓉西蓝花';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,3,'cuisine'  FROM dish WHERE name='蒜蓉西蓝花';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,7,'tag'      FROM dish WHERE name='蒜蓉西蓝花';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 300 FROM dish d, ingredient i WHERE d.name='蒜蓉西蓝花' AND i.name='西蓝花';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10  FROM dish d, ingredient i WHERE d.name='蒜蓉西蓝花' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 2   FROM dish d, ingredient i WHERE d.name='蒜蓉西蓝花' AND i.name='食盐';

-- 3.4 清炒虾仁 category=8 tag=7 diff=2 prep=10 cook=5
INSERT INTO dish(name, note, prep_time, cook_time, price, difficulty) VALUES ('清炒虾仁','清淡高蛋白',10,5,30,2);
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,1,'虾仁去虾线洗净沥水',1 FROM dish WHERE name='清炒虾仁';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,2,'黄瓜切丁',2 FROM dish WHERE name='清炒虾仁';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,3,'热油炒虾仁至变色',3 FROM dish WHERE name='清炒虾仁';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,4,'加黄瓜丁、盐炒匀',4 FROM dish WHERE name='清炒虾仁';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,8,'category' FROM dish WHERE name='清炒虾仁';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,7,'tag'      FROM dish WHERE name='清炒虾仁';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 200 FROM dish d, ingredient i WHERE d.name='清炒虾仁' AND i.name='虾仁';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 100 FROM dish d, ingredient i WHERE d.name='清炒虾仁' AND i.name='黄瓜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10  FROM dish d, ingredient i WHERE d.name='清炒虾仁' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 2   FROM dish d, ingredient i WHERE d.name='清炒虾仁' AND i.name='食盐';

-- 3.5 香煎鸡胸肉 category=8 tag=7 diff=2 prep=10 cook=10
INSERT INTO dish(name, note, prep_time, cook_time, price, difficulty) VALUES ('香煎鸡胸肉','高蛋白低脂',10,10,15,2);
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,1,'鸡胸肉切片用盐腌制 10 分钟',1 FROM dish WHERE name='香煎鸡胸肉';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,2,'热油下锅煎制',2 FROM dish WHERE name='香煎鸡胸肉';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,3,'煎至两面金黄',3 FROM dish WHERE name='香煎鸡胸肉';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,4,'切片装盘',4 FROM dish WHERE name='香煎鸡胸肉';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,8,'category' FROM dish WHERE name='香煎鸡胸肉';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,7,'tag'      FROM dish WHERE name='香煎鸡胸肉';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 200 FROM dish d, ingredient i WHERE d.name='香煎鸡胸肉' AND i.name='鸡胸肉';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10  FROM dish d, ingredient i WHERE d.name='香煎鸡胸肉' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 2   FROM dish d, ingredient i WHERE d.name='香煎鸡胸肉' AND i.name='食盐';

-- 3.6 肉末豆腐 category=8 cuisine=2 tag=6 diff=2 prep=10 cook=10
INSERT INTO dish(name, note, prep_time, cook_time, price, difficulty) VALUES ('肉末豆腐','咸香下饭',10,10,18,2);
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,1,'豆腐切块',1 FROM dish WHERE name='肉末豆腐';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,2,'猪肉剁成肉末',2 FROM dish WHERE name='肉末豆腐';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,3,'热油炒肉末变色',3 FROM dish WHERE name='肉末豆腐';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,4,'加豆腐、水炖煮入味',4 FROM dish WHERE name='肉末豆腐';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,5,'收汁出锅',5 FROM dish WHERE name='肉末豆腐';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,8,'category' FROM dish WHERE name='肉末豆腐';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,2,'cuisine'  FROM dish WHERE name='肉末豆腐';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,6,'tag'      FROM dish WHERE name='肉末豆腐';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 300 FROM dish d, ingredient i WHERE d.name='肉末豆腐' AND i.name='豆腐(北)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 100 FROM dish d, ingredient i WHERE d.name='肉末豆腐' AND i.name='猪肉(瘦)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10  FROM dish d, ingredient i WHERE d.name='肉末豆腐' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 3   FROM dish d, ingredient i WHERE d.name='肉末豆腐' AND i.name='食盐';

-- 3.7 凉拌黄瓜 category=9 tag=7,5 diff=1 prep=5 cook=0
INSERT INTO dish(name, note, prep_time, cook_time, price, difficulty) VALUES ('凉拌黄瓜','爽口凉菜',5,0,6,1);
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,1,'黄瓜拍碎切段',1 FROM dish WHERE name='凉拌黄瓜';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,2,'加盐、醋、蒜泥拌匀',2 FROM dish WHERE name='凉拌黄瓜';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,9,'category' FROM dish WHERE name='凉拌黄瓜';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,7,'tag'      FROM dish WHERE name='凉拌黄瓜';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,5,'tag'      FROM dish WHERE name='凉拌黄瓜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 300 FROM dish d, ingredient i WHERE d.name='凉拌黄瓜' AND i.name='黄瓜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 2   FROM dish d, ingredient i WHERE d.name='凉拌黄瓜' AND i.name='食盐';

-- 3.8 蒸蛋羹(宝宝辅食) category=10 tag=7 diff=1 prep=3 cook=10
INSERT INTO dish(name, note, prep_time, cook_time, price, difficulty) VALUES ('蒸蛋羹','宝宝辅食，嫩滑易消化',3,10,5,1);
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,1,'鸡蛋打散，加 1.5 倍温水搅匀',1 FROM dish WHERE name='蒸蛋羹';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,2,'过滤蛋液去泡',2 FROM dish WHERE name='蒸蛋羹';
INSERT INTO dish_step(dish_id, seq, text, sort_order) SELECT id,3,'中火蒸 10 分钟至凝固',3 FROM dish WHERE name='蒸蛋羹';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,10,'category' FROM dish WHERE name='蒸蛋羹';
INSERT INTO dish_dict(dish_id, dict_id, rel_type) SELECT id,7,'tag'      FROM dish WHERE name='蒸蛋羹';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 100 FROM dish d, ingredient i WHERE d.name='蒸蛋羹' AND i.name='鸡蛋';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 1   FROM dish d, ingredient i WHERE d.name='蒸蛋羹' AND i.name='食盐';

-- ============================================================
-- 4. 菜单(3个)
-- ============================================================

-- 4.1 周末家宴 type=13 target=张爸爸 serving=4
INSERT INTO menu(name, type_id, target_member_id, serving_count)
  VALUES ('周末家宴', 13, (SELECT id FROM member WHERE name='张爸爸'), 4);
INSERT INTO menu_dish(menu_id, dish_id, serving_factor)
  SELECT m.id, d.id, 1 FROM menu m, dish d WHERE m.name='周末家宴' AND d.name='番茄炒蛋';
INSERT INTO menu_dish(menu_id, dish_id, serving_factor)
  SELECT m.id, d.id, 1 FROM menu m, dish d WHERE m.name='周末家宴' AND d.name='青椒土豆丝';
INSERT INTO menu_dish(menu_id, dish_id, serving_factor)
  SELECT m.id, d.id, 1 FROM menu m, dish d WHERE m.name='周末家宴' AND d.name='清炒虾仁';
INSERT INTO menu_dish(menu_id, dish_id, serving_factor)
  SELECT m.id, d.id, 1 FROM menu m, dish d WHERE m.name='周末家宴' AND d.name='蒜蓉西蓝花';

-- 4.2 老人清淡餐 type=12 target=张爷爷 serving=2
INSERT INTO menu(name, type_id, target_member_id, serving_count)
  VALUES ('老人清淡餐', 12, (SELECT id FROM member WHERE name='张爷爷'), 2);
INSERT INTO menu_dish(menu_id, dish_id, serving_factor)
  SELECT m.id, d.id, 1 FROM menu m, dish d WHERE m.name='老人清淡餐' AND d.name='清炒虾仁';
INSERT INTO menu_dish(menu_id, dish_id, serving_factor)
  SELECT m.id, d.id, 1 FROM menu m, dish d WHERE m.name='老人清淡餐' AND d.name='蒜蓉西蓝花';
INSERT INTO menu_dish(menu_id, dish_id, serving_factor)
  SELECT m.id, d.id, 1 FROM menu m, dish d WHERE m.name='老人清淡餐' AND d.name='凉拌黄瓜';

-- 4.3 宝宝辅食餐 type=15 target=小宝 serving=1
INSERT INTO menu(name, type_id, target_member_id, serving_count)
  VALUES ('宝宝辅食餐', 15, (SELECT id FROM member WHERE name='小宝'), 1);
INSERT INTO menu_dish(menu_id, dish_id, serving_factor)
  SELECT m.id, d.id, 1 FROM menu m, dish d WHERE m.name='宝宝辅食餐' AND d.name='蒸蛋羹';
INSERT INTO menu_dish(menu_id, dish_id, serving_factor)
  SELECT m.id, d.id, 1 FROM menu m, dish d WHERE m.name='宝宝辅食餐' AND d.name='蒜蓉西蓝花';

COMMIT;
