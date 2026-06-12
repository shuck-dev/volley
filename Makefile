.PHONY: concepts lfs-upload-setup

concepts:
	git lfs pull --include="concepts/**"

lfs-upload-setup:
	@if [ -z "$$LFS_UPLOAD_KEY" ]; then \
		echo "Error: LFS_UPLOAD_KEY is not set."; \
		echo "Obtain your upload key from a maintainer, then run:"; \
		echo "  LFS_UPLOAD_KEY=<your-key> make lfs-upload-setup"; \
		exit 1; \
	fi
	git config lfs.url "https://volley:$$LFS_UPLOAD_KEY@volley-lfs-proxy.volcanoem.workers.dev"
	@echo "Local lfs.url written to .git/config (not committed)."
	@echo "Normal git add / commit / push of LFS-tracked art now uploads to preview/."
