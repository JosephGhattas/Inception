NAME        = inception
COMPOSE     = docker compose -f srcs/docker-compose.yml

DATA_DIR    = /home/jghattas/data
WP_DIR      = $(DATA_DIR)/wordpress
DB_DIR      = $(DATA_DIR)/mariadb


all: up

setup:
	@mkdir -p $(WP_DIR)
	@mkdir -p $(DB_DIR)
	@chmod 755 $(DATA_DIR)
	@chmod 755 $(WP_DIR)
	@chmod 755 $(DB_DIR)

up: setup
	@$(COMPOSE) up --build -d

down:
	@$(COMPOSE) down

clean:
	@$(COMPOSE) down -v

fclean: clean
	@docker system prune -af
	@sudo rm -rf $(WP_DIR)/* $(DB_DIR)/*

re: fclean up

ps:
	@docker ps

.PHONY: all up down clean fclean re ps setup
