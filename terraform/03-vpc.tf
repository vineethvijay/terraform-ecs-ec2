resource "aws_vpc" "ecs_cluster" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags = "${merge(
    local.tags,
    map("Name", "ECS Cluster VPC")
  )}"
}

//  Create an Internet Gateway for the VPC.
resource "aws_internet_gateway" "ecs_cluster" {
  vpc_id = "${aws_vpc.ecs_cluster.id}"

  tags = "${merge(
    local.tags,
    map("Name", "ECS Cluster IGW")
  )}"
}

resource "aws_subnet" "public_subnet" {
  count                   = "${length(var.subnets)}"
  vpc_id                  = "${aws_vpc.ecs_cluster.id}"
  cidr_block              = "${cidrsubnet(aws_vpc.ecs_cluster.cidr_block, 8, count.index)}"
  map_public_ip_on_launch = true
  depends_on              = ["aws_internet_gateway.ecs_cluster"]
  availability_zone       = "${element(keys(var.subnets), count.index)}"

  //  Use our common tags and add a specific name.
  tags = "${merge(
    local.tags,
    map("Name", "ECS Cluster Public Subnet ${count.index+1}")
  )}"
}

resource "aws_subnet" "private_subnet" {
  count             = "${length(var.subnets)}"
  vpc_id            = "${aws_vpc.ecs_cluster.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.ecs_cluster.cidr_block, 8, length(var.subnets) + count.index)}"
  availability_zone = "${element(keys(var.subnets), count.index)}"
  depends_on        = ["aws_internet_gateway.ecs_cluster"]

  tags = "${merge(
    local.tags,
    map("Name", "ECS Cluster Private Subnet ${count.index+1}")
  )}"

}


//  Create a route table allowing all addresses access to the IGW.
resource "aws_route_table" "public_routes" {
  vpc_id = "${aws_vpc.ecs_cluster.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ecs_cluster.id}"
  }

  tags = "${merge(
    local.tags,
    map("Name", "ECS Cluster Public Route Table")
  )}"
}

//  Associate the route table with the public subnets
resource "aws_route_table_association" "public_subnet_routes" {
  count = "${length(var.subnets)}"

  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_routes.id}"
}


# Create a NAT gateway with an EIP for each private subnet to get internet(outbound) connectivity
resource "aws_eip" "eip" {
  count      = 3
  vpc        = true
  depends_on = ["aws_internet_gateway.ecs_cluster"]
}

resource "aws_nat_gateway" "gw" {
  count         = 3
  subnet_id     = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  allocation_id = "${element(aws_eip.eip.*.id, count.index)}"
}

# Create a new route table for the private subnets, route non-local traffic through the NAT gateway
resource "aws_route_table" "private" {
  count  = 3
  vpc_id = "${aws_vpc.ecs_cluster.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.gw.*.id, count.index)}"
  }
}

# Associate the route table to the private subnets
resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
