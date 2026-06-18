package com.yanhuo.xsd.modules.member;

import cn.dev33.satoken.stp.StpUtil;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.yanhuo.xsd.common.PageQuery;
import com.yanhuo.xsd.common.R;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/member")
@RequiredArgsConstructor
@Tag(name = "家庭成员")
public class MemberController {

    private final MemberService svc;

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
