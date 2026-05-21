package cm.agrocam.erp.controller;

import cm.agrocam.erp.entity.Supplier;
import cm.agrocam.erp.repository.SupplierRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/erp/suppliers")
@RequiredArgsConstructor
public class SupplierController {

    private final SupplierRepository repo;

    @GetMapping
    @Cacheable("suppliers")
    public List<Supplier> getAll() {
        return repo.findAll();
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    @CacheEvict(value = "suppliers", allEntries = true)
    public Supplier create(@RequestBody Supplier supplier) {
        return repo.save(supplier);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    @CacheEvict(value = "suppliers", allEntries = true)
    public ResponseEntity<Supplier> update(@PathVariable Long id, @RequestBody Supplier supplier) {
        return repo.findById(id).map(s -> {
            supplier.setId(id);
            return ResponseEntity.ok(repo.save(supplier));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @CacheEvict(value = "suppliers", allEntries = true)
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        if (!repo.existsById(id)) return ResponseEntity.notFound().build();
        repo.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
