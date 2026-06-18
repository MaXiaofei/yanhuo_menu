package com.yanhuo.xsd.modules.member;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * 家庭成员。healthProfile 存 JSON（身高/体重/忌口/特殊人群/营养约束等），用 JacksonTypeHandler 映射成 Map。
 */
@Data
@TableName(value = "member", autoResultMap = true)
public class Member {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String name;

    /** 角色标签，逗号分隔（关联 sys_dict role）。 */
    private String roleTags;

    /** 健康档案 JSON，灵活存三高指标/忌口/特殊人群/营养约束。 */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private Map<String, Object> healthProfile;

    /**
     * 小程序功能权限 key 数组(JSON)。如 ["dish.create","menu.plan"]。
     * null 时走角色默认模板;非空时与角色默认取并集(个人勾选只能增不能减)。
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<String> mpPermissions;

    private LocalDateTime createTime;

    @TableLogic
    private Integer deleted;
}
