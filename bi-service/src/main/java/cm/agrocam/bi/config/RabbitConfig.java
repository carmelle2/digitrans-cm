package cm.agrocam.bi.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {

    public static final String SHIPMENT_EXCHANGE = "shipment.exchange";
    public static final String BI_QUEUE = "bi.shipment.queue";
    public static final String ROUTING_KEY = "shipment.status.changed";

    @Bean
    public TopicExchange shipmentExchange() {
        return new TopicExchange(SHIPMENT_EXCHANGE);
    }

    @Bean
    public Queue biQueue() {
        return new Queue(BI_QUEUE, true);
    }

    @Bean
    public Binding biBinding() {
        return BindingBuilder.bind(biQueue()).to(shipmentExchange()).with(ROUTING_KEY);
    }

    @Bean
    public Jackson2JsonMessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
