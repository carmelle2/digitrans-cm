package cm.agrocam.erp.controller;

import cm.agrocam.erp.entity.Employee;
import cm.agrocam.erp.repository.EmployeeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/erp/employees")
@RequiredArgsConstructor
public class EmployeeController {

    private final EmployeeRepository repo;

    @GetMapping
    @Cacheable("employees")
    public List<Employee> getAll() {
        return repo.findAll();
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    @CacheEvict(value = "employees", allEntries = true)
    public Employee create(@RequestBody Employee employee) {
        return repo.save(employee);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    @CacheEvict(value = "employees", allEntries = true)
    public ResponseEntity<Employee> update(@PathVariable Long id, @RequestBody Employee employee) {
        return repo.findById(id).map(e -> {
            employee.setId(id);
            return ResponseEntity.ok(repo.save(employee));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @CacheEvict(value = "employees", allEntries = true)
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        if (!repo.existsById(id)) return ResponseEntity.notFound().build();
        repo.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
