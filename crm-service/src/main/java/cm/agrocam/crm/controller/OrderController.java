package cm.agrocam.crm.controller;

import cm.agrocam.crm.entity.Order;
import cm.agrocam.crm.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/crm/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderRepository repo;

    @GetMapping
    @Cacheable("orders")
    public List<Order> getAll() {
        return repo.findAll();
    }

    @PostMapping
    @CacheEvict(value = "orders", allEntries = true)
    public Order create(@RequestBody Order order) {
        return repo.save(order);
    }

    @PutMapping("/{id}/status")
    @CacheEvict(value = "orders", allEntries = true)
    public ResponseEntity<Order> updateStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        return repo.findById(id).map(o -> {
            o.setStatus(Order.OrderStatus.valueOf(body.get("status")));
            return ResponseEntity.ok(repo.save(o));
        }).orElse(ResponseEntity.notFound().build());
    }
}
