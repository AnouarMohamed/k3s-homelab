# Storage bootstrap secrets

KSOPS decrypts three placeholder credential Secrets only inside Argo CD's renderer,
after creating the required namespaces. Longhorn, CloudNativePG, and Velero deliberately
use separate S3 identities so each can be restricted to its own prefix.

Re-encrypt all files with my age recipient before syncing. Test ciphertext and
recipient linkage offline with `make validate-storage`; never decrypt into the working
tree.
