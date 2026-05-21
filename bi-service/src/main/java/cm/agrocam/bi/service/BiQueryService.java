package cm.agrocam.bi.service;

import cm.agrocam.bi.dto.DashboardKpi;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.*;

@Service
public class BiQueryService {

    private final DataSource erpDs;
    private final DataSource crmDs;
    private final DataSource supplyDs;

    public BiQueryService(
        @Qualifier("erpDataSource") DataSource erpDs,
        @Qualifier("crmDataSource") DataSource crmDs,
        @Qualifier("supplyDataSource") DataSource supplyDs
    ) {
        this.erpDs = erpDs;
        this.crmDs = crmDs;
        this.supplyDs = supplyDs;
    }

    @Cacheable("bi-dashboard")
    public DashboardKpi getDashboard() {
        long employees = queryLong(erpDs, "SELECT COUNT(*) FROM employees WHERE status='ACTIVE'");
        long orders = queryLong(crmDs, "SELECT COUNT(*) FROM orders");
        long activeShipments = queryLong(supplyDs, "SELECT COUNT(*) FROM shipments WHERE status='IN_TRANSIT'");
        BigDecimal revenue = queryDecimal(crmDs,
            "SELECT COALESCE(SUM(total_amount),0) FROM orders WHERE MONTH(created_at)=MONTH(NOW()) AND YEAR(created_at)=YEAR(NOW()) AND status='DELIVERED'");
        return new DashboardKpi(employees, orders, activeShipments, revenue);
    }

    @Cacheable("bi-order-stats")
    public Map<String, Object> getOrderStats() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("byStatus", queryList(crmDs,
            "SELECT status, COUNT(*) as count FROM orders GROUP BY status"));
        result.put("byCity", queryList(crmDs,
            "SELECT c.city, COUNT(o.id) as count FROM orders o JOIN customers c ON o.customer_id=c.id GROUP BY c.city"));
        result.put("byMonth", queryList(crmDs,
            "SELECT DATE_FORMAT(created_at,'%Y-%m') as month, COUNT(*) as count FROM orders GROUP BY DATE_FORMAT(created_at,'%Y-%m') ORDER BY month"));
        return result;
    }

    @Cacheable("bi-supply-stats")
    public Map<String, Object> getSupplyStats() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("stockByCategory", queryList(supplyDs,
            "SELECT category, SUM(current_stock) as total FROM products GROUP BY category"));
        result.put("delayedShipments", queryLong(supplyDs,
            "SELECT COUNT(*) FROM shipments WHERE status='IN_TRANSIT' AND arrival_date < CURDATE()"));
        return result;
    }

    @Cacheable("bi-monthly-revenue")
    public List<Map<String, Object>> getMonthlyRevenue() {
        return queryList(crmDs,
            "SELECT DATE_FORMAT(created_at,'%Y-%m') as month, COALESCE(SUM(total_amount),0) as revenue " +
            "FROM orders WHERE YEAR(created_at)=YEAR(NOW()) AND status='DELIVERED' " +
            "GROUP BY DATE_FORMAT(created_at,'%Y-%m') ORDER BY month");
    }

    private long queryLong(DataSource ds, String sql) {
        try (Connection c = ds.getConnection(); Statement s = c.createStatement(); ResultSet rs = s.executeQuery(sql)) {
            return rs.next() ? rs.getLong(1) : 0L;
        } catch (Exception e) { return 0L; }
    }

    private BigDecimal queryDecimal(DataSource ds, String sql) {
        try (Connection c = ds.getConnection(); Statement s = c.createStatement(); ResultSet rs = s.executeQuery(sql)) {
            return rs.next() ? rs.getBigDecimal(1) : BigDecimal.ZERO;
        } catch (Exception e) { return BigDecimal.ZERO; }
    }

    private List<Map<String, Object>> queryList(DataSource ds, String sql) {
        List<Map<String, Object>> rows = new ArrayList<>();
        try (Connection c = ds.getConnection(); Statement s = c.createStatement(); ResultSet rs = s.executeQuery(sql)) {
            int cols = rs.getMetaData().getColumnCount();
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                for (int i = 1; i <= cols; i++) row.put(rs.getMetaData().getColumnLabel(i), rs.getObject(i));
                rows.add(row);
            }
        } catch (Exception e) { /* return empty on failure */ }
        return rows;
    }
}
