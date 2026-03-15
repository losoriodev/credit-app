.PHONY: help setup deps db.setup db.migrate db.reset run test console format lint docker.up docker.down docker.build k8s.apply k8s.delete seed

help: ## Show this help
	@grep -E '^[a-zA-Z_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- Development ---

setup: deps db.setup ## Initial project setup (deps + DB + seeds)
	mix assets.setup
	@echo "\n✅ Setup complete! Run 'make run' to start the server."

deps: ## Install dependencies
	mix deps.get

db.setup: ## Create and migrate database + run seeds
	mix ecto.setup

db.migrate: ## Run pending migrations
	mix ecto.migrate

db.reset: ## Drop, create, and migrate database
	mix ecto.reset

seed: ## Run database seeds
	mix run priv/repo/seeds.exs

run: ## Start Phoenix server
	mix phx.server

iex: ## Start Phoenix server with IEx shell
	iex -S mix phx.server

console: ## Open IEx console
	iex -S mix

test: ## Run all tests
	mix test

test.watch: ## Run tests in watch mode
	mix test --stale --listen-on-stdin

format: ## Format code
	mix format

lint: ## Run compile warnings check
	mix compile --warnings-as-errors

# --- Docker ---

docker.up: ## Start services with Docker Compose
	docker compose up -d

docker.down: ## Stop Docker Compose services
	docker compose down

docker.build: ## Build Docker image
	docker build -t credit-app:latest .

docker.logs: ## View Docker logs
	docker compose logs -f

# --- Kubernetes ---

k8s.apply: ## Apply all Kubernetes manifests
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/postgres.yaml
	kubectl apply -f k8s/app.yaml
	kubectl apply -f k8s/worker.yaml
	kubectl apply -f k8s/ingress.yaml

k8s.migrate: ## Run database migrations in K8s
	kubectl apply -f k8s/migration-job.yaml

k8s.delete: ## Delete all Kubernetes resources
	kubectl delete namespace credit-app

k8s.status: ## Check K8s deployment status
	kubectl get all -n credit-app
