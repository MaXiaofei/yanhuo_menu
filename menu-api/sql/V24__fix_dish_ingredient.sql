-- ============================================================
-- V24__fix_dish_ingredient.sql
-- 治本修复：重挂 dish_ingredient(消除 V23 留下的孤儿)
-- ------------------------------------------------------------
-- 背景：V23__ingredients_ext.sql 原幂等逻辑「按 name 删 ingredient
--   再重插」，会把 V14/V15 demo 食材(番茄 id=1、鸡蛋 id=2 等)删掉后
--   重插到新自增 id(番茄=63、鸡蛋=138…)。但 dish_ingredient 只存
--   ingredient_id + amount(没存 name)，仍引用旧 id(1/2/16/17/18…)
--   → 形成 113/117 孤儿，菜品→食材关联断，采购清单/营养汇总/饮食
--   汇全取不到食材。
-- 修复策略：dish_ingredient 全清，再按 V14(8菜)+V15(10菜) 原始 INSERT
--   (INSERT...SELECT by name) 重挂——用 ingredient 表当前真实 id 重新
--   匹配，不再依赖旧 id。用量(amount)与 V14/V15 一一对应，不改动。
-- 特性：幂等(DELETE 全清 + by name 重挂，可重复执行)。
-- 注：只在 dish/ingredient 都存在时挂载(SELECT 无匹配则 0 行，安全跳过)。
-- ============================================================

-- 1) 全清 dish_ingredient(含所有孤儿/旧关联)
DELETE FROM dish_ingredient;

-- ============================================================
-- 2) V14 番茄炒蛋等 8 道菜(by name 重挂，用量同 V14)
-- ============================================================

-- 番茄炒蛋
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

-- 青椒土豆丝
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 300 FROM dish d, ingredient i WHERE d.name='青椒土豆丝' AND i.name='土豆';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 100 FROM dish d, ingredient i WHERE d.name='青椒土豆丝' AND i.name='青椒';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10  FROM dish d, ingredient i WHERE d.name='青椒土豆丝' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 3   FROM dish d, ingredient i WHERE d.name='青椒土豆丝' AND i.name='食盐';

-- 蒜蓉西蓝花
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 300 FROM dish d, ingredient i WHERE d.name='蒜蓉西蓝花' AND i.name='西蓝花';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10  FROM dish d, ingredient i WHERE d.name='蒜蓉西蓝花' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 2   FROM dish d, ingredient i WHERE d.name='蒜蓉西蓝花' AND i.name='食盐';

-- 清炒虾仁
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 200 FROM dish d, ingredient i WHERE d.name='清炒虾仁' AND i.name='虾仁';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 100 FROM dish d, ingredient i WHERE d.name='清炒虾仁' AND i.name='黄瓜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10  FROM dish d, ingredient i WHERE d.name='清炒虾仁' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 2   FROM dish d, ingredient i WHERE d.name='清炒虾仁' AND i.name='食盐';

-- 香煎鸡胸肉
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 200 FROM dish d, ingredient i WHERE d.name='香煎鸡胸肉' AND i.name='鸡胸肉';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10  FROM dish d, ingredient i WHERE d.name='香煎鸡胸肉' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 2   FROM dish d, ingredient i WHERE d.name='香煎鸡胸肉' AND i.name='食盐';

-- 肉末豆腐
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 300 FROM dish d, ingredient i WHERE d.name='肉末豆腐' AND i.name='豆腐(北)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 100 FROM dish d, ingredient i WHERE d.name='肉末豆腐' AND i.name='猪肉(瘦)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10  FROM dish d, ingredient i WHERE d.name='肉末豆腐' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 3   FROM dish d, ingredient i WHERE d.name='肉末豆腐' AND i.name='食盐';

-- 凉拌黄瓜
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 300 FROM dish d, ingredient i WHERE d.name='凉拌黄瓜' AND i.name='黄瓜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 2   FROM dish d, ingredient i WHERE d.name='凉拌黄瓜' AND i.name='食盐';

-- 蒸蛋羹
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 100 FROM dish d, ingredient i WHERE d.name='蒸蛋羹' AND i.name='鸡蛋';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 1   FROM dish d, ingredient i WHERE d.name='蒸蛋羹' AND i.name='食盐';

-- ============================================================
-- 3) V15 红烧肉等 10 道菜(by name 重挂，用量同 V15)
-- ============================================================

-- 红烧肉
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 350 FROM dish d, ingredient i WHERE d.name='红烧肉' AND i.name='五花肉';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='红烧肉' AND i.name='冰糖';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='红烧肉' AND i.name='酱油(生抽)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='红烧肉' AND i.name='酱油(老抽)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='红烧肉' AND i.name='料酒';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='红烧肉' AND i.name='生姜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='红烧肉' AND i.name='大葱';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 5 FROM dish d, ingredient i WHERE d.name='红烧肉' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 2 FROM dish d, ingredient i WHERE d.name='红烧肉' AND i.name='食盐';

-- 宫保鸡丁
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 350 FROM dish d, ingredient i WHERE d.name='宫保鸡丁' AND i.name='鸡胸肉';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 50 FROM dish d, ingredient i WHERE d.name='宫保鸡丁' AND i.name='花生';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 80 FROM dish d, ingredient i WHERE d.name='宫保鸡丁' AND i.name='大葱';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 50 FROM dish d, ingredient i WHERE d.name='宫保鸡丁' AND i.name='青椒';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='宫保鸡丁' AND i.name='生姜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='宫保鸡丁' AND i.name='大蒜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 20 FROM dish d, ingredient i WHERE d.name='宫保鸡丁' AND i.name='酱油(生抽)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='宫保鸡丁' AND i.name='醋';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='宫保鸡丁' AND i.name='白糖';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='宫保鸡丁' AND i.name='料酒';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='宫保鸡丁' AND i.name='淀粉';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 20 FROM dish d, ingredient i WHERE d.name='宫保鸡丁' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 2 FROM dish d, ingredient i WHERE d.name='宫保鸡丁' AND i.name='食盐';

-- 麻婆豆腐
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 400 FROM dish d, ingredient i WHERE d.name='麻婆豆腐' AND i.name='豆腐(嫩)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 80 FROM dish d, ingredient i WHERE d.name='麻婆豆腐' AND i.name='猪肉(瘦)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 20 FROM dish d, ingredient i WHERE d.name='麻婆豆腐' AND i.name='豆瓣酱';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='麻婆豆腐' AND i.name='大蒜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='麻婆豆腐' AND i.name='生姜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='麻婆豆腐' AND i.name='酱油(生抽)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='麻婆豆腐' AND i.name='淀粉';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='麻婆豆腐' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 2 FROM dish d, ingredient i WHERE d.name='麻婆豆腐' AND i.name='食盐';

-- 糖醋排骨
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 500 FROM dish d, ingredient i WHERE d.name='糖醋排骨' AND i.name='排骨';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 40 FROM dish d, ingredient i WHERE d.name='糖醋排骨' AND i.name='白糖';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 25 FROM dish d, ingredient i WHERE d.name='糖醋排骨' AND i.name='醋';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='糖醋排骨' AND i.name='酱油(生抽)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 5 FROM dish d, ingredient i WHERE d.name='糖醋排骨' AND i.name='酱油(老抽)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='糖醋排骨' AND i.name='料酒';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='糖醋排骨' AND i.name='生姜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='糖醋排骨' AND i.name='大葱';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 20 FROM dish d, ingredient i WHERE d.name='糖醋排骨' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='糖醋排骨' AND i.name='淀粉';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 2 FROM dish d, ingredient i WHERE d.name='糖醋排骨' AND i.name='食盐';

-- 可乐鸡翅
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 400 FROM dish d, ingredient i WHERE d.name='可乐鸡翅' AND i.name='鸡翅';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 300 FROM dish d, ingredient i WHERE d.name='可乐鸡翅' AND i.name='可乐';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='可乐鸡翅' AND i.name='酱油(生抽)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 3 FROM dish d, ingredient i WHERE d.name='可乐鸡翅' AND i.name='酱油(老抽)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='可乐鸡翅' AND i.name='白糖';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='可乐鸡翅' AND i.name='料酒';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='可乐鸡翅' AND i.name='生姜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 5 FROM dish d, ingredient i WHERE d.name='可乐鸡翅' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 2 FROM dish d, ingredient i WHERE d.name='可乐鸡翅' AND i.name='食盐';

-- 鱼香肉丝
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 200 FROM dish d, ingredient i WHERE d.name='鱼香肉丝' AND i.name='猪肉(瘦)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 100 FROM dish d, ingredient i WHERE d.name='鱼香肉丝' AND i.name='胡萝卜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 100 FROM dish d, ingredient i WHERE d.name='鱼香肉丝' AND i.name='青椒';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='鱼香肉丝' AND i.name='木耳(干)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='鱼香肉丝' AND i.name='豆瓣酱';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='鱼香肉丝' AND i.name='酱油(生抽)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='鱼香肉丝' AND i.name='醋';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='鱼香肉丝' AND i.name='白糖';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='鱼香肉丝' AND i.name='料酒';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='鱼香肉丝' AND i.name='淀粉';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='鱼香肉丝' AND i.name='大葱';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='鱼香肉丝' AND i.name='生姜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='鱼香肉丝' AND i.name='大蒜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 20 FROM dish d, ingredient i WHERE d.name='鱼香肉丝' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 2 FROM dish d, ingredient i WHERE d.name='鱼香肉丝' AND i.name='食盐';

-- 清蒸鲈鱼
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 400 FROM dish d, ingredient i WHERE d.name='清蒸鲈鱼' AND i.name='鲈鱼';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 30 FROM dish d, ingredient i WHERE d.name='清蒸鲈鱼' AND i.name='大葱';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 20 FROM dish d, ingredient i WHERE d.name='清蒸鲈鱼' AND i.name='生姜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='清蒸鲈鱼' AND i.name='酱油(生抽)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='清蒸鲈鱼' AND i.name='料酒';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='清蒸鲈鱼' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 5 FROM dish d, ingredient i WHERE d.name='清蒸鲈鱼' AND i.name='食盐';

-- 西红柿鸡蛋汤
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 200 FROM dish d, ingredient i WHERE d.name='西红柿鸡蛋汤' AND i.name='番茄';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 100 FROM dish d, ingredient i WHERE d.name='西红柿鸡蛋汤' AND i.name='鸡蛋';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 5 FROM dish d, ingredient i WHERE d.name='西红柿鸡蛋汤' AND i.name='大葱';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='西红柿鸡蛋汤' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 3 FROM dish d, ingredient i WHERE d.name='西红柿鸡蛋汤' AND i.name='食盐';

-- 紫菜蛋花汤
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 10 FROM dish d, ingredient i WHERE d.name='紫菜蛋花汤' AND i.name='紫菜(干)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 100 FROM dish d, ingredient i WHERE d.name='紫菜蛋花汤' AND i.name='鸡蛋';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 5 FROM dish d, ingredient i WHERE d.name='紫菜蛋花汤' AND i.name='大葱';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 5 FROM dish d, ingredient i WHERE d.name='紫菜蛋花汤' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 2 FROM dish d, ingredient i WHERE d.name='紫菜蛋花汤' AND i.name='食盐';

-- 虎皮青椒
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 250 FROM dish d, ingredient i WHERE d.name='虎皮青椒' AND i.name='青椒';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='虎皮青椒' AND i.name='大蒜';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='虎皮青椒' AND i.name='酱油(生抽)';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='虎皮青椒' AND i.name='醋';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 15 FROM dish d, ingredient i WHERE d.name='虎皮青椒' AND i.name='白糖';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 20 FROM dish d, ingredient i WHERE d.name='虎皮青椒' AND i.name='食用油';
INSERT INTO dish_ingredient(dish_id, ingredient_id, amount)
  SELECT d.id, i.id, 3 FROM dish d, ingredient i WHERE d.name='虎皮青椒' AND i.name='食盐';

-- ============================================================
-- 预期：18 道菜 × 各自食材用量 = 共 117 行(全为 V14/V15 原始用量)
--   V14(8菜)：5+4+3+4+3+4+2+2 = 27 行
--   V15(10菜)：9+12+9+11+9+15+7+5+5+7 = 90 行
--   (若 dish/ingredient 都存在则全挂；缺失则 SELECT 0 行，安全跳过)
-- ============================================================
