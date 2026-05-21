package cm.agrocam.supply.controller;

import cm.agrocam.supply.config.RabbitConfig;
import cm.agrocam.supply.entity.Checkpoint;
import cm.agrocam.supply.entity.Shipment;
import cm.agrocam.supply.messaging.ShipmentStatusChangedEvent;
import cm.agrocam.supply.repository.CheckpointRepository;
import cm.agrocam.supply.repository.ShipmentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/supply/shipments")
@RequiredArgsConstructor
public class ShipmentController {

    private final ShipmentRepository shipmentRepo;
    private final CheckpointRepository checkpointRepo;
    private final RabbitTemplate rabbitTemplate;

    @GetMapping
    @Cacheable("shipments")
    public List<Shipment> getAll() {
        return shipmentRepo.findAll();
    }

    @PostMapping
    @CacheEvict(value = "shipments", allEntries = true)
    public Shipment create(@RequestBody Shipment shipment) {
        return shipmentRepo.save(shipment);
    }

    @PutMapping("/{id}/status")
    @CacheEvict(value = "shipments", allEntries = true)
    public ResponseEntity<Shipment> updateStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        return shipmentRepo.findById(id).map(s -> {
            String previous = s.getStatus().name();
            s.setStatus(Shipment.ShipmentStatus.valueOf(body.get("status")));
            Shipment saved = shipmentRepo.save(s);
            rabbitTemplate.convertAndSend(
                RabbitConfig.SHIPMENT_EXCHANGE,
                RabbitConfig.ROUTING_KEY,
                new ShipmentStatusChangedEvent(saved.getId(), saved.getTrackingCode(), previous, saved.getStatus().name())
            );
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/{id}/checkpoint")
    public ResponseEntity<Checkpoint> addCheckpoint(@PathVariable Long id, @RequestBody Checkpoint checkpoint) {
        return shipmentRepo.findById(id).map(s -> {
            checkpoint.setShipmentId(id);
            return ResponseEntity.ok(checkpointRepo.save(checkpoint));
        }).orElse(ResponseEntity.notFound().build());
    }
}
