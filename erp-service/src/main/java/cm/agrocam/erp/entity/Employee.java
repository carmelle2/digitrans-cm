package cm.agrocam.erp.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "employees")
@Data
public class Employee {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String fullName;

    @Column(nullable = false, unique = true)
    private String email;

    private String role;
    private String department;

    @Column(precision = 15, scale = 2)
    private BigDecimal salary;

    private LocalDate hireDate;

    @Column(nullable = false)
    private String status = "ACTIVE";
}
