package migrations

import "embed"

// Files contains the ordered SQL migrations applied by the API migration mode.
//
//go:embed *.sql
var Files embed.FS
