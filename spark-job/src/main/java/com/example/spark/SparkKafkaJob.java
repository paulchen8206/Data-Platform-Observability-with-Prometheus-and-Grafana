package com.example.spark;

import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SparkSession;
import org.apache.spark.sql.functions;
import org.apache.spark.sql.streaming.StreamingQuery;

public class SparkKafkaJob {
  public static void main(String[] args) throws Exception {
    SparkSession spark =
        SparkSession.builder()
            .appName("Spark Kafka Stream Aggregator")
            .getOrCreate();

    Dataset<Row> kafkaRows =
        spark.readStream()
            .format("kafka")
            .option("kafka.bootstrap.servers", "kafka:9092")
            .option("subscribe", "platform-events")
            .option("startingOffsets", "latest")
            .load();

    Dataset<Row> values = kafkaRows.selectExpr("CAST(value AS STRING) AS raw_value");

    Dataset<Row> eventCounts =
        values
            .withColumn("eventType", functions.split(values.col("raw_value"), ",").getItem(0))
            .groupBy("eventType")
            .count();

    StreamingQuery query =
        eventCounts.writeStream()
            .outputMode("complete")
            .format("console")
            .option("truncate", "false")
            .option("numRows", "20")
            .start();

    query.awaitTermination();
  }
}
