package com.example.producer;

import java.time.Instant;
import java.util.Properties;
import java.util.Random;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;

public class EventProducerApplication {
  private static final String[] EVENT_TYPES = {
    "order-created",
    "payment-authorized",
    "shipment-scheduled",
    "refund-issued"
  };

  public static void main(String[] args) throws Exception {
    String bootstrapServers = System.getenv().getOrDefault("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092");
    String topic = System.getenv().getOrDefault("KAFKA_TOPIC", "platform-events");

    Properties props = new Properties();
    props.put("bootstrap.servers", bootstrapServers);
    props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
    props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
    props.put("acks", "all");
    props.put("retries", "5");

    Random random = new Random();

    try (KafkaProducer<String, String> producer = new KafkaProducer<>(props)) {
      while (true) {
        String eventType = EVENT_TYPES[random.nextInt(EVENT_TYPES.length)];
        String payload = eventType + ",ts=" + Instant.now() + ",value=" + random.nextInt(1000);

        producer.send(new ProducerRecord<>(topic, eventType, payload));
        producer.flush();

        System.out.println("Produced: " + payload);
        Thread.sleep(1000);
      }
    }
  }
}
