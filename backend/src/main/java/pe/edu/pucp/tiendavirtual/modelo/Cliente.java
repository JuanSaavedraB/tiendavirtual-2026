package pe.edu.pucp.tiendavirtual.modelo;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "CLIENTE")
@Getter
@Setter
public class Cliente {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "dni", length = 8, nullable = false, unique = true)
    private String dni;

    @Column(name = "nombre", length = 80, nullable = false)
    private String nombre;

    @Column(name = "apellidos", length = 80, nullable = false)
    private String apellidos;
}
