package cm.agrocam.supply.repository;

import cm.agrocam.supply.entity.Checkpoint;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CheckpointRepository extends JpaRepository<Checkpoint, Long> {
    List<Checkpoint> findByShipmentId(Long shipmentId);
}
