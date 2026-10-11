terraform {
  backend "s3" {
    # Runtime-only endpoint, bucket, credentials, and encryption options are
    # passed with -backend-config. State configuration is never committed.
  }
}
