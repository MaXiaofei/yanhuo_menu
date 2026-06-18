-- V19: member 小程序功能权限矩阵
-- mp_permissions: 功能权限 key 数组(JSON),如 ["dish.create","menu.plan","pantry.manage","health.view"]
-- null 时走角色(role)默认模板;非空时与角色默认取并集(个人勾选只能增不能减,符合「微调放宽」语义)
ALTER TABLE member ADD COLUMN mp_permissions JSON;
