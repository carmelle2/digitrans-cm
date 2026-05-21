package cm.agrocam.bi.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.cache.CacheManager;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class ShipmentEventListener {

    private static final Logger log = LoggerFactory.getLogger(ShipmentEventListener.class);
    private final CacheManager cacheManager;

    public ShipmentEventListener(CacheManager cacheManager) {
        this.cacheManager = cacheManager;
    }

    @RabbitListener(queues = RabbitConfig.BI_QUEUE)
    public void onShipmentStatusChanged(Map<String, Object> event) {
        log.info("[BI] Shipment status changed: {}, evicting BI caches", event.get("shipmentId"));
        cacheManager.getCacheNames().forEach(name -> {
            var cache = cacheManager.getCache(name);
            if (cache != null) cache.clear();
        });
    }
}
