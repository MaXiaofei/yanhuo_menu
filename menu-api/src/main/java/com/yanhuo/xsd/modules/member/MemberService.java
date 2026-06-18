package com.yanhuo.xsd.modules.member;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.yanhuo.xsd.common.PageQuery;
import com.yanhuo.xsd.modules.member.mapper.MemberMapper;
import org.springframework.stereotype.Service;

@Service
public class MemberService extends ServiceImpl<MemberMapper, Member> {

    /** 分页查（后台管理）。按创建时间倒序。 */
    public IPage<Member> page(PageQuery q) {
        return page(new Page<>(q.getPageNum(), q.getPageSize()),
                new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<Member>()
                        .orderByDesc("create_time"));
    }
}
