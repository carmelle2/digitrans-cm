package cm.agrocam.crm.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "restaurants")
@Data
public class Restaurant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private String city;
    private String address;
    private String managerName;

    @Column(columnDefinition = "TINYINT(1)")
    private Boolean isActive = true;
}
