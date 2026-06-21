-- ============================================================
-- V29 user+member 合并：member 加账号字段(phone/password_hash/is_admin)
-- admin 账号从 user 表迁到 member(is_admin=1,phone='admin')
-- 幂等：先 SHOW COLUMNS 确认不存在再加；admin 行用 NOT EXISTS 防重插
-- ============================================================

-- ---- 1. member 加三列(幂等:信息_schema 判列是否存在) ----
SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS
              WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'member' AND COLUMN_NAME = 'phone');
SET @sql := IF(@col = 0, 'ALTER TABLE member ADD COLUMN phone VARCHAR(20)', 'SELECT "phone exists"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS
              WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'member' AND COLUMN_NAME = 'password_hash');
SET @sql := IF(@col = 0, 'ALTER TABLE member ADD COLUMN password_hash VARCHAR(128)', 'SELECT "password_hash exists"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS
              WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'member' AND COLUMN_NAME = 'is_admin');
SET @sql := IF(@col = 0, 'ALTER TABLE member ADD COLUMN is_admin TINYINT DEFAULT 0', 'SELECT "is_admin exists"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---- 2. phone 加唯一索引(幂等)——同一手机号只能绑一个 member ----
SET @idx := (SELECT COUNT(*) FROM information_schema.STATISTICS
              WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'member' AND INDEX_NAME = 'uk_member_phone');
SET @sql := IF(@idx = 0,
  'ALTER TABLE member ADD UNIQUE INDEX uk_member_phone (phone)',
  'SELECT "uk_member_phone exists"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---- 3. admin 迁移到 member(从 user 表取 password_hash)----
--     name='掌勺人', phone='admin', is_admin=1, role_tags='32'(掌勺全权)
--     NOT EXISTS 防重:若已有 phone='admin' 的 member 则跳过
INSERT INTO member(name, phone, password_hash, is_admin, role_tags, health_profile)
SELECT '掌勺人', 'admin', u.password_hash, 1, '32', '{}'
FROM user u
WHERE u.username = 'admin'
  AND NOT EXISTS (SELECT 1 FROM member m WHERE m.phone = 'admin');

-- 兜底:user 表无 admin 种子(如部分库)时,用 V01 同款 BCrypt 哈希(admin123)直接种
INSERT INTO member(name, phone, password_hash, is_admin, role_tags, health_profile)
SELECT '掌勺人', 'admin', '$2a$10$UM6Ql8.rTKA1aGBSup2ACu4ol4WikGIlfyAPPSciymgdPMpWqa/Ba', 1, '32', '{}'
WHERE NOT EXISTS (SELECT 1 FROM member m WHERE m.phone = 'admin');
