package cm.agrocam.bi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
public class BiServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(BiServiceApplication.class, args);
    }
}
