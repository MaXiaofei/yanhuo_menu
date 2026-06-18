package com.yanhuo.xsd.modules.member;

import cn.dev33.satoken.stp.StpUtil;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.yanhuo.xsd.common.PageQuery;
import com.yanhuo.xsd.common.R;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/member")
@RequiredArgsConstructor
@Tag(name = "家庭成员")
public class MemberController {

    private final MemberService svc;
    private final MpPermissionService permSvc;

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
        svc.save(m);
        return R.ok(m.getId());
    }

    @PutMapping
    public R<?> update(@RequestBody Member m) {
        svc.updateById(m);
        return R.ok(null);
    }

    @DeleteMapping("/{id}")
    public R<?> del(@PathVariable Long id) {
        svc.removeById(id);
        return R.ok(null);
    }
}
