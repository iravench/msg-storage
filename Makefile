REDIS_NAME        ?= msg-storage-redis
MYSQL_NAME        ?= msg-storage-mysql
RABBIT_NAME       ?= msg-storage-rabbit

SQL_PATH=$(shell realpath init.sql)

all:
	@echo "available targets:"
	@echo "  * local       - create a local docker vm for development"
	@echo "  * dps         - list all running containers on the local docker vm"
	@echo "  * up          - run both redis and mysql servers as docker containers"
	@echo "  * down        - stop and remove the redis and mysql containers"
	@echo "  * redis_logs  - display logs of the redis server container"
	@echo "  * redis_cli   - enter the redis command line interface"
	@echo "  * mysql_logs  - display logs of the mysql server container"
	@echo "  * mysql_cli   - enter the mysql command line interface"
	@echo "  * mysql_init  - run initial scripts to create mysql msg db"
	@echo "  * rabbit_logs - display logs of the rabbitmq server container"
	@echo "  * rabbit_cli  - enter the rabbitmq command line interface"
local:
	docker-machine start local || true
	docker-machine create -d virtualbox --virtualbox-memory 3072 local || true
dps:
	eval $$(docker-machine env local) && \
	docker ps
up: local
	eval $$(docker-machine env local) && \
	docker run -d -p 6379:6379 \
	  --name $(REDIS_NAME) \
	  --hostname $(REDIS_NAME) \
	  redis:alpine || true && \
	docker run -d -p 3306:3306 \
	  --name $(MYSQL_NAME) \
	  --hostname $(MYSQL_NAME) \
	  -e MYSQL_ROOT_PASSWORD=pink5678 \
	  -e MYSQL_DATABASE=bex-msg \
	  -e MYSQL_USER=pink \
	  -e MYSQL_PASSWORD=5678 \
	  mysql:latest || true && \
	docker run -d -p 15672:15672 -p 5672:5672 \
	  --name $(RABBIT_NAME) \
	  --hostname $(RABBIT_NAME) \
	  -e RABBITMQ_ERLANG_COOKIE='pink5678' \
	  -e RABBITMQ_DEFAULT_USER=guest \
	  -e RABBITMQ_DEFAULT_PASS=guest \
	  rabbitmq:3-management || true && \
	until $(MAKE) mysql_init; do sleep 1s; done
down:
	eval $$(docker-machine env local) && \
	docker rm -f $(REDIS_NAME) && \
	docker rm -f $(MYSQL_NAME) && \
	docker rm -f $(RABBIT_NAME)
redis_logs:
	eval $$(docker-machine env local) && \
	docker logs $(REDIS_NAME)
redis_cli:
	eval $$(docker-machine env local) && \
	docker run -it --link $(REDIS_NAME):redis --rm redis:alpine \
	  redis-cli -h redis -p 6379
mysql_logs:
	eval $$(docker-machine env local) && \
	docker logs $(MYSQL_NAME)
mysql_shell:
	eval $$(docker-machine env local) && \
	docker exec -it $(MYSQL_NAME) sh
mysql_init:
	eval $$(docker-machine env local) && \
	docker run -it --link $(MYSQL_NAME):mysql --rm \
	  -v $(SQL_PATH):/tmp/init.sql \
	  mysql sh -c \
	  'exec mysql \
	  -h"$$MYSQL_PORT_3306_TCP_ADDR" \
	  -P"$$MYSQL_PORT_3306_TCP_PORT" \
	  -D"$$MYSQL_ENV_MYSQL_DATABASE" \
	  -u"$$MYSQL_ENV_MYSQL_USER" \
	  -p"$$MYSQL_ENV_MYSQL_PASSWORD" \
	  -e"source /tmp/init.sql"'
mysql_cli:
	eval $$(docker-machine env local) && \
	docker run -it --link $(MYSQL_NAME):mysql --rm mysql sh -c \
	  'exec mysql \
	  -h"$$MYSQL_PORT_3306_TCP_ADDR" \
	  -P"$$MYSQL_PORT_3306_TCP_PORT" \
	  -D"$$MYSQL_ENV_MYSQL_DATABASE" \
	  -u"$$MYSQL_ENV_MYSQL_USER" \
	  -p"$$MYSQL_ENV_MYSQL_PASSWORD"'
rabbit_cli:
	eval $$(docker-machine env local) && \
	docker run -it --link $(RABBIT_NAME):rabbit --rm \
	  -e RABBITMQ_ERLANG_COOKIE='pink5678' \
	  -e RABBITMQ_NODENAME=rabbit@$(RABBIT_NAME) \
	  rabbitmq:3 bash
rabbit_logs:
	eval $$(docker-machine env local) && \
	docker logs $(RABBIT_NAME)
FORCE:
