terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.62.0"
    }
  }
}

provider aws {
  shared_config_files      = ["/Users/dgraymullen/.aws/config"]
  shared_credentials_files = ["/Users/dgraymullen/.aws/credentials"]
  assume_role {
    role_arn     = "arn:aws:iam::381491844601:role/account-lightsail-role"
    session_name = "UpdateContainerServiceInstance"
    external_id  = "OpenTofu-Dev"
  }
}

resource "aws_lightsail_container_service" "microblog-flask-tutorial" {
  name        = "microblog-flask-tutorial"
  power       = "micro"
  scale       = 1
  is_disabled = false

  public_domain_names {
    certificate {
      certificate_name = "Certificate-1"
      domain_names = [
        "www.micro-blog.org",
        "micro-blog.org"
      ]
    }
  }
  tags = {
  }
}

variable "MAIL_PORT" {
  type        = number
  description = "Port of mail server"
}

variable "DATABASE_URL" {
  type        = string
  description = "Url of db"
}

variable "MAIL_USERNAME" {
  type        = string
  description = "Username for mail server"
}

variable "ELASTICSEARCH_URL" {
  type        = string
  description = "Url of Elasticsearch"
}

variable "SECRET_KEY" {
  type        = string
  description = "backend secret key"
}

variable "MAIL_SERVER" {
  type        = string
  description = "url of mail server"
}

variable "MAIL_PASSWORD" {
  type        = string
  description = "password for mail server"
}

variable "REDIS_URL" {
  type        = string
  description = "url for redis cluster"
}

resource "aws_lightsail_container_service_deployment_version" "microblog-flask-tutorial-version" {
  container {
    container_name = "microblog"
    image          = ":microblog-flask-tutorial.microblog.16"

    environment = {
      MAIL_PORT = var.MAIL_PORT
      DATABASE_URL = var.DATABASE_URL
      MAIL_USERNAME = var.MAIL_USERNAME
      MAIL_USE_TLS = true
      ELASTICSEARCH_URL = var.ELASTICSEARCH_URL
      SECRET_KEY = var.SECRET_KEY
      MAIL_SERVER = var.MAIL_SERVER
      MAIL_PASSWORD = var.MAIL_PASSWORD
      REDIS_URL = var.REDIS_URL
    }

    ports = {
      5000 = "HTTP"
    }
  }
  container {
    container_name = "microblog-worker"
    image          = ":microblog-flask-tutorial.microblog-worker.9"

    environment = {
      MAIL_PORT = var.MAIL_PORT
      DATABASE_URL = var.DATABASE_URL
      MAIL_USERNAME = var.MAIL_USERNAME
      MAIL_USE_TLS = true
      ELASTICSEARCH_URL = var.ELASTICSEARCH_URL
      SECRET_KEY = var.SECRET_KEY
      MAIL_SERVER = var.MAIL_SERVER
      MAIL_PASSWORD = var.MAIL_PASSWORD
      REDIS_URL = var.REDIS_URL
    }
  }

  container {
    container_name = "elasticsearch"
    image          = "docker.elastic.co/elasticsearch/elasticsearch:7.17.19"

    environment = {
      "discovery.type" = "single-node"
      "xpack.security.enabled" = false
    }

    ports = {
      9200 = "TCP"
    }
  }

  container {
    container_name = "redis"
    image          = "redis:latest"

    ports = {
      6379 = "TCP"
    }
  }

  public_endpoint {
    container_name = "microblog"
    container_port = 5000

    health_check {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout_seconds     = 2
      interval_seconds    = 5
      path                = "/"
      success_codes       = "200-499"
    }
  }

  service_name = aws_lightsail_container_service.microblog-flask-tutorial.name
}

