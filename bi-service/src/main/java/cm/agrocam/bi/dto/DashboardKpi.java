package cm.agrocam.bi.dto;

import java.math.BigDecimal;
import java.util.Map;

public record DashboardKpi(
    long totalEmployees,
    long totalOrders,
    long activeShipments,
    BigDecimal monthlyRevenue
) {}
