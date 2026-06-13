package pe.edu.pucp.tiendavirtual.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class ItemPricingService {
    private final String logisticaBaseUrl;
    private final HttpClient httpClient;

    public ItemPricingService(@Value("${app.logistica.productos-base-url:}") String logisticaBaseUrl) {
        this.logisticaBaseUrl = logisticaBaseUrl == null ? "" : logisticaBaseUrl.trim();
        this.httpClient = HttpClient.newHttpClient();
    }

    public ProductSubtotal calcularSubtotal(String codigoProducto, Integer cantidad) {
        if (codigoProducto == null || codigoProducto.isBlank()) {
            throw new IllegalArgumentException("Cada item debe incluir un codigo de producto valido.");
        }
        if (cantidad == null || cantidad <= 0) {
            throw new IllegalArgumentException("La cantidad de cada item debe ser mayor a cero.");
        }
        if (logisticaBaseUrl.isBlank()) {
            throw new IllegalStateException("La URL base de logistica no esta configurada.");
        }

        String codigo = codigoProducto.trim();
        BigDecimal precioUnitario = obtenerPrecioDesdeLogistica(codigo);
        BigDecimal subTotal = precioUnitario
                .multiply(BigDecimal.valueOf(cantidad))
                .setScale(2, RoundingMode.HALF_UP);

        return new ProductSubtotal(
                codigo,
                subTotal
        );
    }

    private BigDecimal obtenerPrecioDesdeLogistica(String codigoProducto) {
        String codigoEncoded = URLEncoder.encode(codigoProducto, StandardCharsets.UTF_8);
        String endpoint = String.format("%s/codigo/%s", logisticaBaseUrl, codigoEncoded);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(endpoint))
                .timeout(Duration.ofSeconds(5))
                .GET()
                .build();

        final HttpResponse<String> response;
        try {
            response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        } catch (IOException e) {
            throw new IllegalStateException("No se pudo consultar Logistica para el producto: " + codigoProducto, e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Consulta a Logistica interrumpida para el producto: " + codigoProducto, e);
        }

        if (response.statusCode() == 404) {
            throw new IllegalArgumentException("Producto no encontrado en Logistica: " + codigoProducto);
        }
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IllegalStateException("Respuesta invalida de Logistica para producto " + codigoProducto + ": " + response.statusCode());
        }

        Matcher matcher = Pattern.compile("\"precio\"\\s*:\\s*([0-9]+(?:\\.[0-9]+)?)").matcher(response.body());
        if (!matcher.find()) {
            throw new IllegalStateException("No se encontró el precio en respuesta de Logistica para: " + codigoProducto);
        }

        return new BigDecimal(matcher.group(1));
    }

    public record ProductSubtotal(String codigoProducto, BigDecimal subTotal) {}
}
