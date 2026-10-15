package com.inventra.api.infrastructure.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

// Isolado do @SpringBootApplication de propósito: se ficasse lá, @WebMvcTest (que não sobe
// contexto JPA) tentaria criar o jpaAuditingHandler e falharia com "JPA metamodel must not be empty".
@Configuration
@EnableJpaAuditing
public class JpaAuditingConfig {
}
