package cm.agrocam.supply.repository;

import cm.agrocam.supply.entity.Shipment;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ShipmentRepository extends JpaRepository<Shipment, Long> {}
