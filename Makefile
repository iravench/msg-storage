REDIS_NAME        ?= msg-storage-redis
MYSQL_NAME        ?= msg-storage-mysql
RABBIT_NAME       ?= msg-storage-rabbit

INIT_SQL=$(shell cat init.sql)

all:
	@echo "available targets:"
	@echo "  * up         - run both redis and mysql servers as docker containers"
	@echo "  * down       - stop and remove the redis and mysql containers"
	@echo "  * redis_logs - display logs of the redis server container"
	@echo "  * mysql_logs - display logs of the mysql server container"
	@echo "  * mysql_init - run initial scripts to create mysql msg db"
	@echo "  * mysql_cli  - enter the mysql command line interface"
up:
	docker run -d -p 6379:6379 \
	  --name $(REDIS_NAME) \
	  --hostname $(REDIS_NAME) \
	  redis:alpine
	docker run -d -p 3306:3306 \
	  --name $(MYSQL_NAME) \
	  --hostname $(MYSQL_NAME) \
	  -e MYSQL_ROOT_PASSWORD=pink5678 \
	  -e MYSQL_DATABASE=bex-msg \
	  -e MYSQL_USER=pink \
	  -e MYSQL_PASSWORD=5678 \
	  mysql:latest
	docker run -d -p 15672:15672 -p 5672:5672 \
	  --name $(RABBIT_NAME) \
	  --hostname $(RABBIT_NAME) \
	  -e RABBITMQ_ERLANG_COOKIE='pink5678' \
	  -e RABBITMQ_DEFAULT_USER=guest \
	  -e RABBITMQ_DEFAULT_PASS=guest \
	  rabbitmq:3-management
	until $(MAKE) mysql_init; do sleep 1s; done
down:
	docker rm -f $(REDIS_NAME)
	docker rm -f $(MYSQL_NAME)
	docker rm -f $(RABBIT_NAME)
redis_logs:
	docker logs $(REDIS_NAME)
redis_cli:
	docker run -it --link $(REDIS_NAME):redis --rm redis:alpine \
	  redis-cli -h redis -p 6379
mysql_logs:
	docker logs $(MYSQL_NAME)
mysql_shell:
	docker exec -it $(MYSQL_NAME) sh
mysql_init:
	docker run -it --link $(MYSQL_NAME):mysql --rm mysql sh -c \
	  'exec mysql \
	  -h"$$MYSQL_PORT_3306_TCP_ADDR" \
	  -P"$$MYSQL_PORT_3306_TCP_PORT" \
	  -D"$$MYSQL_ENV_MYSQL_DATABASE" \
	  -u"$$MYSQL_ENV_MYSQL_USER" \
	  -p"$$MYSQL_ENV_MYSQL_PASSWORD" \
	  -e"$(INIT_SQL)"'
mysql_cli:
	docker run -it --link $(MYSQL_NAME):mysql --rm mysql sh -c \
	  'exec mysql \
	  -h"$$MYSQL_PORT_3306_TCP_ADDR" \
	  -P"$$MYSQL_PORT_3306_TCP_PORT" \
	  -D"$$MYSQL_ENV_MYSQL_DATABASE" \
	  -u"$$MYSQL_ENV_MYSQL_USER" \
	  -p"$$MYSQL_ENV_MYSQL_PASSWORD"'
rabbit_cli:
	docker run -it --link $(RABBIT_NAME):rabbit --rm \
	  -e RABBITMQ_ERLANG_COOKIE='pink5678' \
	  -e RABBITMQ_NODENAME=rabbit@$(RABBIT_NAME) \
	  rabbitmq:3 bash
rabbit_logs:
	docker logs $(RABBIT_NAME)
FORCE:
