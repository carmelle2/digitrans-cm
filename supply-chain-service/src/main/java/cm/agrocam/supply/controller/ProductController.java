package cm.agrocam.supply.controller;

import cm.agrocam.supply.entity.Product;
import cm.agrocam.supply.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/supply/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductRepository repo;

    @GetMapping
    @Cacheable("products")
    public List<Product> getAll() {
        return repo.findAll();
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    @CacheEvict(value = "products", allEntries = true)
    public Product create(@RequestBody Product product) {
        return repo.save(product);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    @CacheEvict(value = "products", allEntries = true)
    public ResponseEntity<Product> update(@PathVariable Long id, @RequestBody Product product) {
        return repo.findById(id).map(p -> {
            product.setId(id);
            return ResponseEntity.ok(repo.save(product));
        }).orElse(ResponseEntity.notFound().build());
    }
}
