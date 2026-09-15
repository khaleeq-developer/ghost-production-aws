data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnets = {
    for index, cidr in var.public_subnet_cidrs : tostring(index) => {
      availability_zone = local.availability_zones[index]
      cidr_block         = cidr
    }
  }

  application_subnets = {
    for index, cidr in var.application_subnet_cidrs : tostring(index) => {
      availability_zone = local.availability_zones[index]
      cidr_block         = cidr
    }
  }

  database_subnets = {
    for index, cidr in var.database_subnet_cidrs : tostring(index) => {
      availability_zone = local.availability_zones[index]
      cidr_block         = cidr
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-public-${each.value.availability_zone}"
    Tier = "public"
  }
}

resource "aws_subnet" "database" {
  for_each = local.database_subnets

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-database-${each.value.availability_zone}"
    Tier = "database"
  }
}

resource "aws_subnet" "application" {
  for_each = local.application_subnets

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-application-${each.value.availability_zone}"
    Tier = "application"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# A single zonal NAT gateway controls cost for this single-environment design.
# It is an intentional egress single point of failure; production HA would use
# one NAT gateway per AZ or a justified VPC endpoint design.
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "application" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["0"].id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.name_prefix}-nat"
  }
}

resource "aws_route_table" "application" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-application-rt"
  }
}

resource "aws_route" "application_internet" {
  route_table_id         = aws_route_table.application.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.application.id
}

resource "aws_route_table_association" "application" {
  for_each = aws_subnet.application

  subnet_id      = each.value.id
  route_table_id = aws_route_table.application.id
}

# This route table intentionally has no internet route.
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-database-rt"
  }
}

resource "aws_route_table_association" "database" {
  for_each = aws_subnet.database

  subnet_id      = each.value.id
  route_table_id = aws_route_table.database.id
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-"
  description = "Public HTTPS application load balancer for Ghost"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-alb-sg"
  }
}

resource "aws_security_group" "ecs" {
  name_prefix = "${var.name_prefix}-ecs-"
  description = "Ghost ECS tasks"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-ecs-sg"
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.name_prefix}-rds-"
  description = "Ghost MySQL database"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_from_internet" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from the internet for HTTPS redirects"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_from_internet" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ghost" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward traffic to Ghost tasks"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = var.ghost_port
  ip_protocol                  = "tcp"
  to_port                      = var.ghost_port
}

resource "aws_vpc_security_group_ingress_rule" "ghost_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Ghost traffic from the ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.ghost_port
  ip_protocol                  = "tcp"
  to_port                      = var.ghost_port
}

# Private tasks use the NAT gateway for image pulls, AWS APIs, and external calls.
resource "aws_vpc_security_group_egress_rule" "ghost_outbound" {
  security_group_id = aws_security_group.ecs.id
  description       = "Outbound access for image pulls, AWS APIs, and updates"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "mysql_from_ghost" {
  security_group_id            = aws_security_group.rds.id
  description                  = "MySQL traffic from Ghost tasks"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
}

resource "aws_lb" "ghost" {
  name_prefix                = "ghost-"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = [for key in sort(keys(aws_subnet.public)) : aws_subnet.public[key].id]
  drop_invalid_header_fields = true
  enable_deletion_protection = false

  tags = {
    Name = "${var.name_prefix}-alb"
  }
}

resource "aws_lb_target_group" "ghost" {
  name_prefix          = "ghost-"
  port                 = var.ghost_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200-399"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.name_prefix}-ghost-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ghost.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.ghost.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ghost.arn
  }
}
