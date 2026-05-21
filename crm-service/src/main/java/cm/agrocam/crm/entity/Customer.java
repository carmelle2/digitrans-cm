package cm.agrocam.crm.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "customers")
@Data
public class Customer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(unique = true)
    private String email;

    private String phone;
    private String city;
    private Integer loyaltyPoints = 0;

    @Column(updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
}
