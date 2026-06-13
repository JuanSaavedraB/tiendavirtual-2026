package pe.edu.pucp.tiendavirtual.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
public class LogisticaSyncPublisher {
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final SqsClient sqsClient;
    private final String queueUrl;

    public LogisticaSyncPublisher(
            @Value("${app.sync.queue-url:${SYNC_QUEUE_URL:}}") String queueUrl
    ) {
        this.queueUrl = queueUrl;
        String awsRegion = Optional.ofNullable(System.getenv("AWS_REGION")).orElse("us-east-1");
        this.sqsClient = SqsClient.builder()
                .region(Region.of(awsRegion))
                .build();
    }

    public void publish(String entity, String operation, Map<String, Object> payload) {
        if (queueUrl == null || queueUrl.isBlank()) {
            throw new IllegalStateException("No se configuro app.sync.queue-url para publicar eventos");
        }

        try {
            String body = objectMapper.writeValueAsString(Map.of(
                    "entity", entity,
                    "operation", operation,
                    "payload", payload
            ));
            SendMessageRequest.Builder requestBuilder = SendMessageRequest.builder()
                    .queueUrl(queueUrl)
                    .messageBody(body);

            if (esColaFifo()) {
                requestBuilder
                        .messageGroupId(resolverMessageGroupId(entity, payload))
                        .messageDeduplicationId(UUID.randomUUID().toString());
            }

            sqsClient.sendMessage(requestBuilder.build());
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("No se pudo serializar el evento para sincronizacion", ex);
        }
    }

    private boolean esColaFifo() {
        return queueUrl.endsWith(".fifo");
    }

    private String resolverMessageGroupId(String entity, Map<String, Object> payload) {
        Object idGrupo = Optional.ofNullable(payload.get("id"))
                .orElse(payload.get("codigo"));
        return idGrupo != null ? entity + "-" + idGrupo : entity;
    }
}
