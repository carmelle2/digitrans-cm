package cm.agrocam.bi.controller;

import cm.agrocam.bi.dto.DashboardKpi;
import cm.agrocam.bi.service.BiQueryService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/bi")
@RequiredArgsConstructor
public class BiController {

    private final BiQueryService biQueryService;

    @GetMapping("/dashboard")
    public DashboardKpi getDashboard() {
        return biQueryService.getDashboard();
    }

    @GetMapping("/orders/stats")
    public Map<String, Object> getOrderStats() {
        return biQueryService.getOrderStats();
    }

    @GetMapping("/supply/stats")
    public Map<String, Object> getSupplyStats() {
        return biQueryService.getSupplyStats();
    }

    @GetMapping("/revenue/monthly")
    public List<Map<String, Object>> getMonthlyRevenue() {
        return biQueryService.getMonthlyRevenue();
    }
}
