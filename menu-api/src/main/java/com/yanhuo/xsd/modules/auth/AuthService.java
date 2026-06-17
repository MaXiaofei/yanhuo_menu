package com.yanhuo.xsd.modules.auth;

import cn.dev33.satoken.stp.StpUtil;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.yanhuo.xsd.common.BizException;
import com.yanhuo.xsd.modules.auth.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * 账号登录：BCrypt 校验 + Sa-Token 发券。
 */
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserMapper userMapper;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public Map<String, Object> login(LoginDTO dto) {
        User u = userMapper.selectOne(new QueryWrapper<User>().eq("username", dto.getUsername()));
        if (u == null || !passwordEncoder.matches(dto.getPassword(), u.getPasswordHash())) {
            throw new BizException("用户名或密码错误");
        }
        StpUtil.login(u.getId());
        return Map.of("token", StpUtil.getTokenValue(), "nickname", u.getNickname());
    }
}
