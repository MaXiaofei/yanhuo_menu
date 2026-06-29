package com.gudu.xsd.modules.ai.dto;

import java.util.List;

/**
 * AI provider 状态视图（GET /ai/provider 返回）。
 *
 * @param current     当前生效的 provider（deepseek/glm/mock）
 * @param providers   全部可选 provider（顺序即后台展示顺序）
 * @param ready       各 provider 是否已就绪：mock 永远 true；deepseek/glm 视 key 是否配置
 */
public record AiProviderInfo(String current, List<String> providers, List<ProviderState> ready) {

    /** 单个 provider 的就绪状态。 */
    public record ProviderState(String provider, boolean ready) { }
}
