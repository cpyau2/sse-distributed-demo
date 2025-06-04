package com.example.sse.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.lang.NonNull;
import org.springframework.web.reactive.config.CorsRegistry;
import org.springframework.web.reactive.config.WebFluxConfigurer;

@Configuration
public class WebConfig implements WebFluxConfigurer {
    
    @Value("${app.cors.allowed-origins}")
    private String[] allowedOrigins;
    
    @Override
    public void addCorsMappings(@NonNull CorsRegistry registry) {
        registry.addMapping("/**")
            .allowedOrigins(allowedOrigins)
            .allowedMethods("GET", "POST", "DELETE", "OPTIONS")
            .allowedHeaders("*")
            .allowCredentials(true);
    }
}