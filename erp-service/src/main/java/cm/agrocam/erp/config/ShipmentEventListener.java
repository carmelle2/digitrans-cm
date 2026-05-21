package cm.agrocam.erp.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class ShipmentEventListener {

    private static final Logger log = LoggerFactory.getLogger(ShipmentEventListener.class);

    @RabbitListener(queues = RabbitConfig.ERP_QUEUE)
    public void onShipmentStatusChanged(Map<String, Object> event) {
        log.info("[ERP] Shipment status changed: shipmentId={}, newStatus={}",
            event.get("shipmentId"), event.get("newStatus"));
        // Extend: update accounting entries or trigger alerts
    }
}
