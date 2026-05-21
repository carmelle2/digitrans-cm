package cm.agrocam.erp.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "accounting_entries")
@Data
public class AccountingEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String label;

    @Column(precision = 15, scale = 2, nullable = false)
    private BigDecimal amount;

    @Column(length = 10)
    private String currency = "XAF";

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EntryType type;

    private LocalDate date;
    private String reference;

    public enum EntryType { DEBIT, CREDIT }
}
