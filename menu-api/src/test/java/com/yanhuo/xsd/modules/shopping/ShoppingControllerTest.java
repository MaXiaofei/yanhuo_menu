package com.yanhuo.xsd.modules.shopping;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.ibatis.mapping.Environment;
import org.apache.ibatis.session.Configuration;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.defaults.DefaultSqlSessionFactory;
import org.apache.ibatis.transaction.TransactionFactory;
import org.apache.ibatis.transaction.jdbc.JdbcTransactionFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

import javax.sql.DataSource;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * MockMvc 接口测试：mock ShoppingService，验证关键端点。
 * 范式照 PantryControllerTest：@WebMvcTest + 排除 SaTokenConfig + mock SqlSessionFactory 装配 Mapper bean。
 * generate 端点带 @MpPerm(shopping.generate)；切片下未选成员时切面放行，故 200。
 */
@WebMvcTest(
        value = ShoppingController.class,
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.ASSIGNABLE_TYPE,
                classes = com.yanhuo.xsd.config.SaTokenConfig.class))
@Import(ShoppingControllerTest.TestSqlConfig.class)
class ShoppingControllerTest {

    @TestConfiguration
    static class TestSqlConfig {
        @Bean
        DataSource dataSource() {
            return org.mockito.Mockito.mock(DataSource.class);
        }

        @Bean
        SqlSessionFactory sqlSessionFactory(DataSource ds) {
            TransactionFactory tx = new JdbcTransactionFactory();
            Environment env = new Environment("test", tx, ds);
            Configuration cfg = new Configuration(env);
            return new DefaultSqlSessionFactory(cfg);
        }
    }

    @Autowired
    private MockMvc mvc;

    @MockBean
    private ShoppingService svc;

    private final ObjectMapper om = new ObjectMapper();

    /** 造一个明细 VO（带中文）。 */
    private ShoppingItemVO itemVO(Long id, String ing, BigDecimal amt, String unit, String cat) {
        ShoppingItemVO v = new ShoppingItemVO();
        v.setId(id);
        v.setListId(1L);
        v.setIngredientId(10L);
        v.setIngredientName(ing);
        v.setTotalAmount(amt);
        v.setUnitId(20L);
        v.setUnitName(unit);
        v.setPurchaseCategoryId(24L);
        v.setPurchaseCategoryName(cat);
        v.setPurchased(0);
        return v;
    }

    @Test
    void 从周计划生成_返回listId() throws Exception {
        given(svc.generateFromPlan(eq(7L), eq("week"))).willReturn(99L);

        mvc.perform(post("/shopping/generate").param("planId", "7").param("timeRange", "week"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data").value(99));
        verify(svc).generateFromPlan(eq(7L), eq("week"));
    }

    @Test
    void 查采购清单详情_返回带中文items和分区() throws Exception {
        ShoppingListVO vo = new ShoppingListVO();
        vo.setId(1L);
        vo.setSourcePlanId(7L);
        vo.setTimeRange("week");
        vo.setStartDate(LocalDate.of(2026, 6, 16));
        vo.setEndDate(LocalDate.of(2026, 6, 22));
        ShoppingItemVO tomato = itemVO(1L, "番茄", new BigDecimal("500"), "g", "蔬菜");
        vo.setItems(List.of(tomato));
        vo.setGrouped(Map.of(24L, List.of(tomato)));
        vo.setCategoryNames(Map.of(24L, "蔬菜"));
        given(svc.getDetail(eq(1L))).willReturn(vo);

        mvc.perform(get("/shopping/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.id").value(1))
                .andExpect(jsonPath("$.data.items[0].ingredientName").value("番茄"))
                .andExpect(jsonPath("$.data.items[0].unitName").value("g"))
                .andExpect(jsonPath("$.data.items[0].purchaseCategoryName").value("蔬菜"))
                .andExpect(jsonPath("$.data.items[0].totalAmount").value(500));
    }

    @Test
    void 勾选已买_调用service() throws Exception {
        mvc.perform(put("/shopping/item/5/purchased"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));
        verify(svc).togglePurchased(5L);
    }

    @Test
    void 删除明细_调用service() throws Exception {
        mvc.perform(delete("/shopping/item/5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));
        verify(svc).deleteItem(5L);
    }

    @Test
    void 删除整张清单_调用service() throws Exception {
        mvc.perform(delete("/shopping/8"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));
        verify(svc).deleteList(8L);
    }
}
