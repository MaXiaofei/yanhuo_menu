package com.gudu.xsd.modules.ai.dto;

import java.util.List;

/**
 * 菜单推荐响应：候选组列表 + token 用量。
 */
public record MenuRecommendResponse(List<MenuCandidate> groups, int tokensIn, int tokensOut) {
    public MenuRecommendResponse(List<MenuCandidate> groups) {
        this(groups, 0, 0);
    }
}
