package cm.agrocam.crm.repository;

import cm.agrocam.crm.entity.Order;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderRepository extends JpaRepository<Order, Long> {}
