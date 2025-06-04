package com.example.sse.config;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import java.time.Duration;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.ReactiveRedisConnectionFactory;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceClientConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.StringRedisSerializer;
import org.springframework.context.annotation.Primary;
// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.beans.factory.annotation.Qualifier;

@Configuration
public class RedisConfig {

    // @Autowired
    // @Qualifier("reactiveRedisConnectionFactory")
    // private ReactiveRedisConnectionFactory reactiveRedisConnectionFactory;
    
    @Bean
    @Primary
    public ReactiveRedisConnectionFactory reactiveRedisConnectionFactory(
            @Value("${spring.data.redis.host:redis}") String host,
            @Value("${spring.data.redis.port:6379}") int port,
            @Value("${spring.data.redis.timeout:5000}") long timeout) {
        RedisStandaloneConfiguration config = new RedisStandaloneConfiguration(host, port);
        LettuceClientConfiguration clientConfig = LettuceClientConfiguration.builder()
            .commandTimeout(Duration.ofMillis(timeout))
            .build();
        return new LettuceConnectionFactory(config, clientConfig);
    }
    
    // @Bean
    // public ReactiveRedisConnectionFactory reactiveRedisConnectionFactory(
    //         @Value("${spring.redis.host}") String host,
    //         @Value("${spring.redis.port}") int port) {
    //     RedisStandaloneConfiguration config = new RedisStandaloneConfiguration(host, port);
    //     LettuceClientConfiguration clientConfig = LettuceClientConfiguration.builder()
    //         .commandTimeout(Duration.ofSeconds(5))
    //         .build();
    //     return new LettuceConnectionFactory(config, clientConfig);
    // }
    
    @Bean
    @Primary
    public ReactiveRedisTemplate<String, String> reactiveRedisTemplate(
            ReactiveRedisConnectionFactory connectionFactory) {
        StringRedisSerializer serializer = new StringRedisSerializer();
        RedisSerializationContext<String, String> serializationContext = 
            RedisSerializationContext.<String, String>newSerializationContext()
                .key(serializer)
                .value(serializer)
                .hashKey(serializer)
                .hashValue(serializer)
                .build();
        return new ReactiveRedisTemplate<>(connectionFactory, serializationContext);
    }
    
    @Bean
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        mapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        return mapper;
    }
}