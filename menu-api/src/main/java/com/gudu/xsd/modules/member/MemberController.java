package com.gudu.xsd.modules.member;

import cn.dev33.satoken.stp.StpUtil;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.gudu.xsd.common.PageQuery;
import com.gudu.xsd.common.R;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/member")
@RequiredArgsConstructor
@Tag(name = "家庭成员")
public class MemberController {

    private final MemberService svc;
    private final MpPermissionService permSvc;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    // ========== Mifflin-St Jeor BMR 常量 ==========
    private static final double MALE_BMR_CONST = 5;
    private static final double FEMALE_BMR_CONST = -161;

    @GetMapping
    public R<IPage<Member>> list(PageQuery q) {
        return R.ok(svc.page(q));
    }

    /** 切换当前就餐成员（存 Sa-Token session）。 */
    @PostMapping("/current")
    public R<?> setCurrent(@RequestParam Long memberId) {
        StpUtil.getSession().set("currentMemberId", memberId);
        return R.ok(null);
    }

    /** 读取当前就餐成员 id。 */
    @GetMapping("/current")
    public R<Long> getCurrent() {
        return R.ok(StpUtil.getSession().getLong("currentMemberId"));
    }

    /** 解析某成员最终权限集合(角色默认 + 个人勾选并集)。供前端按钮显隐。 */
    @GetMapping("/{id}/permissions")
    public R<Set<String>> permissions(@PathVariable Long id) {
        return R.ok(permSvc.resolveByMemberId(id));
    }

    /** 全量功能 key + 中文映射(供后台 member 表单多选项)。 */
    @GetMapping("/permissions/keys")
    public R<Map<String, String>> permKeys() {
        return R.ok(MpPermissionService.allPermLabels());
    }

    @PostMapping
    public R<?> add(@RequestBody Member m) {
        applyPassword(m);
        svc.save(m);
        return R.ok(m.getId());
    }

    @PutMapping
    public R<?> update(@RequestBody Member m) {
        applyPassword(m);
        svc.updateById(m);
        return R.ok(null);
    }

    /**
     * 把表单传入的明文 password( transient )加密为 passwordHash。
     * 留空则不动现有哈希(编辑时不改密码场景)。
     */
    private void applyPassword(Member m) {
        if (m.getPassword() != null && !m.getPassword().isBlank()) {
            m.setPasswordHash(passwordEncoder.encode(m.getPassword()));
        }
        m.setPassword(null);
    }

    @DeleteMapping("/{id}")
    public R<?> del(@PathVariable Long id) {
        svc.removeById(id);
        return R.ok(null);
    }

    /**
     * 计算成员每日营养目标（BMR × 活动系数 + 体控目标调整）。
     *
     * 高度数据从 healthProfile JSON 中取 height(cm)/weight(kg)/age/gender。
     * 目标从 goal 字段取，活动水平从 activityLevel 字段取。
     * 任一缺失返回 null（data=null），前端据此判断是否支持精准模式。
     */
    @GetMapping("/{id}/nutrition-target")
    public R<NutritionTargetResponse> nutritionTarget(@PathVariable Long id) {
        Member m = svc.getById(id);
        if (m == null) return R.ok(null);

        Map<String, Object> hp = m.getHealthProfile();
        if (hp == null) return R.ok(null);

        Object weightObj = hp.get("weight");
        Object heightObj = hp.get("height");
        Object ageObj = hp.get("age");
        Object genderObj = hp.get("gender");

        if (weightObj == null || heightObj == null || ageObj == null) return R.ok(null);

        double weight = toDouble(weightObj);
        double height = toDouble(heightObj);
        int age = toInt(ageObj);
        String gender = genderObj != null ? genderObj.toString() : "male";

        if (weight <= 0 || height <= 0 || age <= 0) return R.ok(null);

        // Mifflin-St Jeor BMR
        double bmr = 10 * weight + 6.25 * height - 5 * age;
        bmr += "female".equalsIgnoreCase(gender) ? FEMALE_BMR_CONST : MALE_BMR_CONST;

        // 活动系数
        String al = m.getActivityLevel();
        double activityMultiplier = activityMultiplier(al);

        double tdee = bmr * activityMultiplier;

        // 体控目标调整
        String goal = m.getGoal();
        double goalAdjust = goalAdjust(goal);
        int calorieTarget = (int) Math.round(tdee + goalAdjust);

        // 蛋白目标：体重(kg) × 系数
        double proteinPerKg = "GAIN".equalsIgnoreCase(goal) ? 2.0
                : "LOSE".equalsIgnoreCase(goal) ? 2.0 : 1.6;
        int proteinTarget = (int) Math.round(weight * proteinPerKg);

        // 脂肪：总热量 × 25%
        int fatTarget = (int) Math.round(calorieTarget * 0.25 / 9);

        // 碳水：剩余热量
        int carbTarget = (int) Math.round((calorieTarget - proteinTarget * 4 - fatTarget * 9) / 4.0);
        if (carbTarget < 0) carbTarget = 0;

        NutritionTargetResponse rsp = new NutritionTargetResponse();
        rsp.setCalorieTarget(calorieTarget);
        rsp.setProteinTarget(proteinTarget);
        rsp.setCarbTarget(carbTarget);
        rsp.setFatTarget(fatTarget);
        rsp.setGoal(goal);
        rsp.setBmr((int) Math.round(bmr));
        return R.ok(rsp);
    }

    private double activityMultiplier(String level) {
        if (level == null) return 1.2;
        return switch (level.toUpperCase()) {
            case "SEDENTARY" -> 1.2;
            case "LIGHT" -> 1.375;
            case "MODERATE" -> 1.55;
            case "ACTIVE" -> 1.725;
            default -> 1.2;
        };
    }

    private double goalAdjust(String goal) {
        if (goal == null) return 0;
        return switch (goal.toUpperCase()) {
            case "LOSE" -> -500;
            case "GAIN" -> 300;
            default -> 0;
        };
    }

    private double toDouble(Object v) {
        if (v instanceof Number n) return n.doubleValue();
        try { return Double.parseDouble(v.toString()); } catch (Exception e) { return 0; }
    }

    private int toInt(Object v) {
        if (v instanceof Number n) return n.intValue();
        try { return Integer.parseInt(v.toString()); } catch (Exception e) { return 0; }
    }
}
