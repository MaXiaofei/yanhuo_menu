package com.yanhuo.xsd.modules.cookbook;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.yanhuo.xsd.modules.cookbook.mapper.CookingRecordMapper;
import com.yanhuo.xsd.modules.cookbook.mapper.FavoriteMapper;
import com.yanhuo.xsd.modules.dish.Dish;
import com.yanhuo.xsd.modules.dish.mapper.DishMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class CookbookService {

    private final FavoriteMapper favoriteMapper;
    private final CookingRecordMapper cookingRecordMapper;
    private final DishMapper dishMapper;

    /** 收藏（幂等：已收藏则跳过）。 */
    public void favorite(Long memberId, Long dishId) {
        Long cnt = favoriteMapper.selectCount(new QueryWrapper<Favorite>()
                .eq("member_id", memberId).eq("dish_id", dishId));
        if (cnt == 0) {
            Favorite f = new Favorite();
            f.setMemberId(memberId);
            f.setDishId(dishId);
            favoriteMapper.insert(f);
        }
    }

    public void unfavorite(Long memberId, Long dishId) {
        favoriteMapper.delete(new QueryWrapper<Favorite>()
                .eq("member_id", memberId).eq("dish_id", dishId));
    }

    /** 某成员收藏的菜品列表。 */
    public List<Dish> listFavorites(Long memberId) {
        List<Favorite> favs = favoriteMapper.selectList(
                new QueryWrapper<Favorite>().eq("member_id", memberId));
        if (favs.isEmpty()) return List.of();
        List<Long> ids = favs.stream().map(Favorite::getDishId).toList();
        return dishMapper.selectBatchIds(ids);
    }

    /** 标记做过：写一条 cooking_record。 */
    public void markDone(Long memberId, Long dishId, String note) {
        CookingRecord r = new CookingRecord();
        r.setDishId(dishId);
        r.setMemberId(memberId);
        r.setCookedAt(LocalDateTime.now());
        r.setNote(note);
        cookingRecordMapper.insert(r);
    }

    /** 做过的菜品（按 cooking_record 去重 dish_id，最近优先）。 */
    public List<Dish> listDone(Long memberId) {
        List<CookingRecord> records = cookingRecordMapper.selectList(
                new QueryWrapper<CookingRecord>().eq("member_id", memberId).orderByDesc("cooked_at"));
        if (records.isEmpty()) return List.of();
        List<Long> ids = records.stream().map(CookingRecord::getDishId).distinct().toList();
        return dishMapper.selectBatchIds(ids);
    }
}
