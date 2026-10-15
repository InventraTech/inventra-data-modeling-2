package com.inventra.api;

import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;

import me.paulschwarz.springdotenv.spring.DotenvApplicationInitializer;

@SpringBootApplication
public class InventraApiApplication {

	public static void main(String[] args) {
		new SpringApplicationBuilder(InventraApiApplication.class)
				.initializers(new DotenvApplicationInitializer())
				.run(args);
	}

}
