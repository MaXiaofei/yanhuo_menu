package com.yanhuo.xsd.modules.dict;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.yanhuo.xsd.modules.dict.mapper.DictMapper;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class DictService extends ServiceImpl<DictMapper, SysDict> {

    public List<SysDict> listByGroup(String group) {
        return list(new QueryWrapper<SysDict>().eq("dict_group", group).orderByAsc("sort"));
    }
}
