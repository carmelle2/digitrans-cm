package cm.agrocam.erp.controller;

import cm.agrocam.erp.entity.AccountingEntry;
import cm.agrocam.erp.repository.AccountingEntryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/erp/accounting")
@RequiredArgsConstructor
public class AccountingController {

    private final AccountingEntryRepository repo;

    @GetMapping
    @Cacheable("accounting")
    public List<AccountingEntry> getAll() {
        return repo.findAll();
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    @CacheEvict(value = "accounting", allEntries = true)
    public AccountingEntry create(@RequestBody AccountingEntry entry) {
        return repo.save(entry);
    }

    @GetMapping("/{id}")
    public ResponseEntity<AccountingEntry> getById(@PathVariable Long id) {
        return repo.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }
}
