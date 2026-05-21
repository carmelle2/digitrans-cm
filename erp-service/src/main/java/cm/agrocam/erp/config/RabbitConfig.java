package cm.agrocam.erp.config;

import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {

    public static final String SHIPMENT_EXCHANGE = "shipment.exchange";
    public static final String ERP_QUEUE = "erp.shipment.queue";
    public static final String ROUTING_KEY = "shipment.status.changed";

    @Bean
    public TopicExchange shipmentExchange() {
        return new TopicExchange(SHIPMENT_EXCHANGE);
    }

    @Bean
    public Queue erpQueue() {
        return new Queue(ERP_QUEUE, true);
    }

    @Bean
    public Binding erpBinding() {
        return BindingBuilder.bind(erpQueue()).to(shipmentExchange()).with(ROUTING_KEY);
    }

    @Bean
    public Jackson2JsonMessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
