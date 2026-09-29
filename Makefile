# MPI Cluster — Root Makefile

include .env
export

COMPOSE := docker compose

.PHONY: help up down restart logs ps shell build clean benchmark metrics

help: ## Tampilkan daftar perintah
	@echo "MPI Cluster — Command Reference"
	@echo "-------------------------------"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

up: ## Build image & jalankan semua container
	$(COMPOSE) up -d --build

down: ## Hentikan & hapus semua container
	$(COMPOSE) down

restart: ## Restart semua container
	$(COMPOSE) restart

logs: ## Tampilkan log semua container
	$(COMPOSE) logs -f

ps: ## Lihat status container
	$(COMPOSE) ps

build: ## Build image saja
	$(COMPOSE) build

shell: ## Masuk ke container master
	docker exec -it master bash

benchmark: ## Jalankan benchmark Pi di dalam master
	docker exec -it master bash /scripts/run-benchmark.sh

metrics: ## Snapshot metrik dari Prometheus
	docker exec -it master bash /scripts/collect-metrics.sh

clean: ## Hapus container + volume
	$(COMPOSE) down -v
	rm -rf results/*.csv results/*.json
