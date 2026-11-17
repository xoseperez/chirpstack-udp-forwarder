# Run from the repository root:
#   docker buildx bake -f docker/docker-bake.hcl

variable "REGISTRY"   { default = "xoseperez/chirpstack-udp-forwarder" }
variable "VERSION"    { default = "dev" }
# Comma-separated extra tags; CI passes "X.Y.Z,X.Y,X,latest" for the newest release.
variable "EXTRA_TAGS" { default = "" }
variable "REVISION"   { default = "" }

target "default" {
  context   = "docker"
  contexts  = { dist = "dist" }
  platforms = ["linux/amd64", "linux/arm64", "linux/arm/v7"]
  tags = concat(
    ["${REGISTRY}:${VERSION}"],
    [for t in split(",", EXTRA_TAGS) : "${REGISTRY}:${t}" if t != ""]
  )
  labels = {
    "org.opencontainers.image.title"    = "ChirpStack UDP Forwarder"
    "org.opencontainers.image.source"   = "https://github.com/xoseperez/chirpstack-udp-forwarder"
    "org.opencontainers.image.version"  = VERSION
    "org.opencontainers.image.revision" = REVISION
  }
}
