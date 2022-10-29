GIT_DESCR = $(shell git describe --tags --always)
DOCKER_REGISTRY = 205035295823.dkr.ecr.eu-central-1.amazonaws.com
DOCKER_TAG = $(GIT_DESCR)
AWS_PROFILE = apeunit

define build_project
    @echo installing dependencies and building
	sh -c 'cd ../$(1) && yarn install && yarn build'
	@echo done
endef

define build_docker_image
    @echo building docker image for $(1)
	sh -c 'cd .. && docker build --platform linux/amd64 --build-arg DOCKER_TAG='$(DOCKER_TAG)' -t $(1) -f $(1)/Dockerfile .'
	@echo done
endef

define push_docker_image
    @echo publishing docker image for $(1)
	docker tag $(1):latest $(DOCKER_REGISTRY)/$(2):$(DOCKER_TAG)
	docker tag $(1):latest $(DOCKER_REGISTRY)/$(2):latest
	docker push --all-tags $(DOCKER_REGISTRY)/$(2)
	@echo done
endef

define redeploy_ecs_service
    @echo building docker image for $(1)
	aws --profile $(AWS_PROFILE) ecs update-service --cluster kanvas-ecs-cluster --service $(1)-service --force-new-deployment
	@echo done
endef

default: create-ecr-repos docker-build-all docker-push-all

create-ecr-repos:
	@echo copy resources
	terraform apply -target="aws_ecr_repository.kanvas_ecr_repos"
	@echo done

docker-build-store-front:
	$(call build_docker_image,store-front)	
	
docker-build-admin-front:
	$(call build_docker_image,admin-front)	

docker-build-store-api-server:
	$(call build_docker_image,store-api-server)	

docker-build-admin-api-server:
	$(call build_docker_image,admin-api-server)	

docker-build-all: docker-build-store-front docker-build-admin-front docker-build-store-api-server docker-build-admin-api-server

docker-login:
	# docker login $(DOCKER_PROVIDER)
	aws --profile $(AWS_PROFILE) ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $(DOCKER_REGISTRY)
	docker login $(DOCKER_REGISTRY)

docker-push-store-front: docker-login
	$(call push_docker_image,store-front,kanvas-store-front)	
	
docker-push-admin-front: docker-login
	$(call push_docker_image,admin-front,kanvas-admin-front)	

docker-push-store-api-server: docker-login
	$(call push_docker_image,store-api-server,kanvas-store-api)	

docker-push-admin-api-server: docker-login
	$(call push_docker_image,admin-api-server,kanvas-admin-api)	

docker-push-all: docker-login docker-push-store-front docker-push-admin-front docker-push-store-api-server docker-push-admin-api-server





ecs-redeploy-store-front:
	$(call redeploy_ecs_service,store-front)
ecs-redeploy-admin-front:
	$(call redeploy_ecs_service,admin-front)	

ecs-redeploy-store-api-server:
	$(call redeploy_ecs_service,store-api)	

ecs-redeploy-admin-api-server:
	$(call redeploy_ecs_service,admin-api)	

ecs-redeploy-all: ecs-redeploy-store-front ecs-redeploy-admin-front ecs-redeploy-store-api-server ecs-redeploy-admin-api-server