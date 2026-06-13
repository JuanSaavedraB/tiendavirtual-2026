package pe.edu.pucp.tiendavirtual.app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.persistence.autoconfigure.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication(scanBasePackages = "pe.edu.pucp.tiendavirtual")
@EntityScan(basePackages = "pe.edu.pucp.tiendavirtual.modelo")
@EnableJpaRepositories(basePackages = "pe.edu.pucp.tiendavirtual.repository")
public class App {

	public static void main(String[] args) {
		SpringApplication.run(App.class, args);
	}

}
