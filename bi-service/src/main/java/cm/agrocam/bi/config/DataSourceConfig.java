package cm.agrocam.bi.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import javax.sql.DataSource;
import com.zaxxer.hikari.HikariDataSource;

@Configuration
public class DataSourceConfig {

    @Bean
    @ConfigurationProperties("spring.datasource.erp")
    public DataSourceProperties erpDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean(name = "erpDataSource")
    @Primary
    public DataSource erpDataSource() {
        return erpDataSourceProperties().initializeDataSourceBuilder().type(HikariDataSource.class).build();
    }

    @Bean
    @ConfigurationProperties("spring.datasource.crm")
    public DataSourceProperties crmDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean(name = "crmDataSource")
    public DataSource crmDataSource() {
        return crmDataSourceProperties().initializeDataSourceBuilder().type(HikariDataSource.class).build();
    }

    @Bean
    @ConfigurationProperties("spring.datasource.supply")
    public DataSourceProperties supplyDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean(name = "supplyDataSource")
    public DataSource supplyDataSource() {
        return supplyDataSourceProperties().initializeDataSourceBuilder().type(HikariDataSource.class).build();
    }
}
