package cm.agrocam.erp.controller;

import com.nimbusds.jose.jwk.source.ImmutableSecret;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.web.bind.annotation.*;

import javax.crypto.spec.SecretKeySpec;
import java.time.Instant;
import java.util.Map;

@RestController
@RequestMapping("/auth")
public class AuthController {

    @Value("${jwt.secret:agrocam-digitrans-secret-key-2024-very-long-secret}")
    private String jwtSecret;

    // Hardcoded demo users — replace with DB-backed UserDetailsService in production
    private static final Map<String, String[]> USERS = Map.of(
        "admin", new String[]{"password", "ROLE_ADMIN"},
        "manager", new String[]{"password", "ROLE_MANAGER"},
        "agent", new String[]{"password", "ROLE_AGENT"},
        "viewer", new String[]{"password", "ROLE_VIEWER"}
    );

    @PostMapping("/login")
    public ResponseEntity<Map<String, String>> login(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        String password = body.get("password");

        String[] user = USERS.get(username);
        if (user == null || !user[0].equals(password)) {
            throw new BadCredentialsException("Invalid credentials");
        }

        byte[] keyBytes = jwtSecret.getBytes();
        SecretKeySpec key = new SecretKeySpec(keyBytes, "HmacSHA256");
        NimbusJwtEncoder encoder = new NimbusJwtEncoder(new ImmutableSecret<>(key));

        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        JwtClaimsSet claims = JwtClaimsSet.builder()
            .subject(username)
            .claim("roles", user[1])
            .issuedAt(Instant.now())
            .expiresAt(Instant.now().plusSeconds(86400))
            .build();

        String token = encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
        return ResponseEntity.ok(Map.of("token", token, "role", user[1]));
    }
}
