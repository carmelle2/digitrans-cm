package cm.agrocam.supply.messaging;

import java.io.Serializable;

public record ShipmentStatusChangedEvent(
    Long shipmentId,
    String trackingCode,
    String previousStatus,
    String newStatus
) implements Serializable {}
