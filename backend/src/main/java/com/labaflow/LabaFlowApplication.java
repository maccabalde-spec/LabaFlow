package com.labaflow;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class LabaFlowApplication {
    public static void main(String[] args) {
        SpringApplication.run(LabaFlowApplication.class, args);
    }
}
