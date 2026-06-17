package com.yanhuo.xsd.modules.member;

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
    public R<List<Member>> list() {
        return R.ok(svc.list());
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
