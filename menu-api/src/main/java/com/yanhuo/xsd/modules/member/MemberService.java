package com.yanhuo.xsd.modules.member;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.yanhuo.xsd.modules.member.mapper.MemberMapper;
import org.springframework.stereotype.Service;

@Service
public class MemberService extends ServiceImpl<MemberMapper, Member> {
}
