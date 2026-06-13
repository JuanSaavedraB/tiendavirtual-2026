package pe.edu.pucp.tiendavirtual.app;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.hibernate.proxy.HibernateProxy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import tools.jackson.databind.json.JsonMapper;

@Configuration
public class JacksonConfig {

    @Bean
    public JsonMapper jacksonJsonMapper() {
        return JsonMapper.builder()
                .addMixIn(HibernateProxy.class, HibernateProxyMixIn.class)
                .build();
    }

    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private interface HibernateProxyMixIn {
    }
}


