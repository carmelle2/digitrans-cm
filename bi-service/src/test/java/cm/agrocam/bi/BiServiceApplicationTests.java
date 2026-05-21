package cm.agrocam.bi;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

@SpringBootTest
@TestPropertySource(properties = {
    "spring.datasource.erp.url=jdbc:h2:mem:erpdb",
    "spring.datasource.crm.url=jdbc:h2:mem:crmdb",
    "spring.datasource.supply.url=jdbc:h2:mem:supplydb",
    "spring.datasource.erp.driver-class-name=org.h2.Driver",
    "spring.datasource.crm.driver-class-name=org.h2.Driver",
    "spring.datasource.supply.driver-class-name=org.h2.Driver"
})
class BiServiceApplicationTests {

    @Test
    void contextLoads() {
    }
}
