package cm.agrocam.supply.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "products")
@Data
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    private Category category;

    private String origin;
    private String unit;
    private Integer currentStock = 0;

    public enum Category { CACAO, COFFEE, FOOD }
}
