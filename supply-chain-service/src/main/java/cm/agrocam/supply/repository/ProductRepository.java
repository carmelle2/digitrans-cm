package cm.agrocam.supply.repository;

import cm.agrocam.supply.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductRepository extends JpaRepository<Product, Long> {}
