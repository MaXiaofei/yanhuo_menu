package com.yanhuo.xsd.modules.dict;

import com.yanhuo.xsd.common.R;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/dict")
@RequiredArgsConstructor
@Tag(name = "配置中心")
public class DictController {

    private final DictService svc;

    @GetMapping
    public R<List<SysDict>> list(@RequestParam String group) {
        return R.ok(svc.listByGroup(group));
    }

    @PostMapping
    public R<?> add(@RequestBody SysDict d) {
        svc.save(d);
        return R.ok(d.getId());
    }

    @PutMapping
    public R<?> update(@RequestBody SysDict d) {
        svc.updateById(d);
        return R.ok(null);
    }

    @DeleteMapping("/{id}")
    public R<?> del(@PathVariable Long id) {
        svc.removeById(id);
        return R.ok(null);
    }
}
