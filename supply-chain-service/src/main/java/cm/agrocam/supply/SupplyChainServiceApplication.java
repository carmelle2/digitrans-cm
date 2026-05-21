package cm.agrocam.supply;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
public class SupplyChainServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(SupplyChainServiceApplication.class, args);
    }
}
