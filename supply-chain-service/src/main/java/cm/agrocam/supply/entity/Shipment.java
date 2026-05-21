package cm.agrocam.supply.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;

@Entity
@Table(name = "shipments")
@Data
public class Shipment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long productId;

    private String origin;
    private String destination;
    private Integer quantity;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ShipmentStatus status = ShipmentStatus.IN_TRANSIT;

    private LocalDate departureDate;
    private LocalDate arrivalDate;

    @Column(unique = true)
    private String trackingCode;

    public enum ShipmentStatus { IN_TRANSIT, DELIVERED, BLOCKED }
}
