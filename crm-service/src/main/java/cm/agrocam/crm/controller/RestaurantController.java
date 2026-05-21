package cm.agrocam.crm.controller;

import cm.agrocam.crm.entity.Restaurant;
import cm.agrocam.crm.repository.RestaurantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/crm/restaurants")
@RequiredArgsConstructor
public class RestaurantController {

    private final RestaurantRepository repo;

    @GetMapping
    @Cacheable("restaurants")
    public List<Restaurant> getAll() {
        return repo.findAll();
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    @CacheEvict(value = "restaurants", allEntries = true)
    public Restaurant create(@RequestBody Restaurant restaurant) {
        return repo.save(restaurant);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    @CacheEvict(value = "restaurants", allEntries = true)
    public ResponseEntity<Restaurant> update(@PathVariable Long id, @RequestBody Restaurant restaurant) {
        return repo.findById(id).map(r -> {
            restaurant.setId(id);
            return ResponseEntity.ok(repo.save(restaurant));
        }).orElse(ResponseEntity.notFound().build());
    }
}
