USE appdb;

CREATE TABLE IF NOT EXISTS page_views (
    id INT PRIMARY KEY,
    page_views INT NOT NULL DEFAULT 0
);

INSERT INTO page_views (id, page_views)
VALUES (1, 0)
ON DUPLICATE KEY UPDATE id = id;