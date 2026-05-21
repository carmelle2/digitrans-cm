package cm.agrocam.crm.controller;

import cm.agrocam.crm.entity.Customer;
import cm.agrocam.crm.repository.CustomerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/crm/customers")
@RequiredArgsConstructor
public class CustomerController {

    private final CustomerRepository repo;

    @GetMapping
    @Cacheable("customers")
    public List<Customer> getAll() {
        return repo.findAll();
    }

    @PostMapping
    @CacheEvict(value = "customers", allEntries = true)
    public Customer create(@RequestBody Customer customer) {
        return repo.save(customer);
    }

    @PutMapping("/{id}")
    @CacheEvict(value = "customers", allEntries = true)
    public ResponseEntity<Customer> update(@PathVariable Long id, @RequestBody Customer customer) {
        return repo.findById(id).map(c -> {
            customer.setId(id);
            return ResponseEntity.ok(repo.save(customer));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    @CacheEvict(value = "customers", allEntries = true)
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        if (!repo.existsById(id)) return ResponseEntity.notFound().build();
        repo.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
