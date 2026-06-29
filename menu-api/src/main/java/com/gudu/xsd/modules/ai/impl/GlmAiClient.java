package com.gudu.xsd.modules.ai.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gudu.xsd.modules.ai.AiOutputGuard;
import com.gudu.xsd.modules.ai.MenuRecommender;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * 智谱 GLM 真 AI 客户端：OpenAI 兼容协议（{@code https://open.bigmodel.cn/api/paas/v4}），
 * 共用逻辑见 {@link OpenAiCompatibleClient}。
 *
 * <p>常驻 {@code @Component}（由 {@code AiClientRouter} 在运行时按 provider 选中委托）。
 * 本类只声明厂商差异：base-url / model(glm-4-plus) / key / source。
 *
 * <p>key 从 {@code gudu.ai.glm.key}（env {@code GLM_API_KEY}）注入，不硬编码。
 */
@Component
public class GlmAiClient extends OpenAiCompatibleClient {

    private static final String SOURCE = "glm";

    @Value("${gudu.ai.glm.base-url:https://open.bigmodel.cn/api/paas/v4}")
    private String baseUrl;

    @Value("${gudu.ai.glm.model:glm-4-plus}")
    private String model;

    @Value("${gudu.ai.glm.key:}")
    private String key;

    /** 生产构造：自建 RestClient（Spring 装配用，多构造时 @Autowired 显式指定）。 */
    @Autowired
    public GlmAiClient(MockAiClient mockFallback, MenuRecommender menuRecommender,
                       ObjectMapper objectMapper, AiOutputGuard outputGuard) {
        super(mockFallback, menuRecommender, objectMapper, outputGuard);
    }

    /** 测试构造：注入 mock RestClient。 */
    public GlmAiClient(RestClient restClient, MockAiClient mockFallback,
                       MenuRecommender menuRecommender, ObjectMapper objectMapper,
                       AiOutputGuard outputGuard) {
        super(restClient, mockFallback, menuRecommender, objectMapper, outputGuard);
    }

    @Override
    protected String baseUrl() {
        return baseUrl;
    }

    @Override
    protected String model() {
        return model;
    }

    @Override
    protected String key() {
        return key;
    }

    /** 包内可见：供 Router 判断该 provider 是否已配 key（GET /ai/provider 展示可用状态）。 */
    public String getKey() {
        return key;
    }

    @Override
    public String provider() {
        return SOURCE;
    }
}
