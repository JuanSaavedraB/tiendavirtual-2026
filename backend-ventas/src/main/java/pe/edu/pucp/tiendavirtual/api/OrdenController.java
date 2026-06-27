package pe.edu.pucp.tiendavirtual.api;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import pe.edu.pucp.tiendavirtual.modelo.Orden;
import pe.edu.pucp.tiendavirtual.service.OrdenService;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/ordenes")
@RequiredArgsConstructor
public class OrdenController {
    private final OrdenService ordenService;

    @GetMapping
    public List<Orden> listar() {
        return ordenService.listar();
    }

    @GetMapping(params = "fecha")
    public ResponseEntity<?> buscarPorFecha(@RequestParam String fecha) {
        LocalDate fechaParseada;
        try {
            fechaParseada = parsearFecha(fecha);
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(ex.getMessage());
        }
        return ResponseEntity.ok(ordenService.buscarPorFecha(fechaParseada));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Orden> obtenerPorId(@PathVariable Integer id) {
        return ordenService.obtenerPorId(id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<?> crear(@RequestBody Orden orden) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(ordenService.crear(orden));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(ex.getMessage());
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> actualizar(@PathVariable Integer id, @RequestBody Orden orden) {
        try {
            return ordenService.actualizar(id, orden)
                    .<ResponseEntity<?>>map(ResponseEntity::ok)
                    .orElseGet(() -> ResponseEntity.notFound().build());
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(ex.getMessage());
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Integer id) {
        if (!ordenService.eliminar(id)) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.noContent().build();
    }

    private LocalDate parsearFecha(String fecha) {
        List<DateTimeFormatter> formatos = new ArrayList<>();
        formatos.add(DateTimeFormatter.ISO_LOCAL_DATE);
        formatos.add(DateTimeFormatter.ofPattern("M/d/uuuu"));
        formatos.add(DateTimeFormatter.ofPattern("MM/dd/uuuu"));
        formatos.add(DateTimeFormatter.ofPattern("d/M/uuuu"));
        formatos.add(DateTimeFormatter.ofPattern("dd/MM/uuuu"));

        for (DateTimeFormatter formato : formatos) {
            try {
                return LocalDate.parse(fecha, formato);
            } catch (DateTimeParseException ignored) {
            }
        }

        throw new IllegalArgumentException("Fecha invalida. Usa formato yyyy-MM-dd.");
    }
}
