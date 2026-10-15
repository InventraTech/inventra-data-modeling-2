package com.inventra.api.infrastructure.redis;

import static org.assertj.core.api.Assertions.assertThat;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;

class MigrationVersionTest {
    @Test
    void flywayVersionsAreUnique() throws Exception {
        try (var files = Files.list(Path.of("src/main/resources/db/migration"))) {
            var counts = files.map(path -> path.getFileName().toString())
                    .filter(name -> name.matches("V[0-9]+__.*\\.sql"))
                    .collect(Collectors.groupingBy(
                            name -> Integer.parseInt(name.substring(1, name.indexOf("__"))),
                            Collectors.counting()));
            assertThat(counts).isNotEmpty();
            assertThat(counts.values()).allMatch(count -> count == 1L);
        }
    }
}
