package cm.agrocam.supply.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "checkpoints")
@Data
public class Checkpoint {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long shipmentId;

    private String location;
    private LocalDateTime timestamp = LocalDateTime.now();
    private String agentName;
    private String note;
}
